(* ResX prototype: specialize typed native JSX after ordinary type checking.
   Dynamic expressions stay in the captured values array; emitters run only
   when the existing renderer visits the block. *)
open Asttypes
open Typedtree

exception Unsupported

type piece = Static of string | Child of expression

let marked name attributes =
  List.exists (fun ({Location.txt}, _) -> txt = name) attributes

let rec longident = function
  | Path.Pident id -> Longident.Lident (Ident.name id)
  | Pdot (parent, name, _) -> Ldot (longident parent, name)
  | Papply _ -> raise Unsupported

let rec identity expr =
  match expr.exp_desc with
  | Texp_apply {
      funct = {exp_desc = Texp_ident (_, _, {val_kind = Val_prim p})};
      args = [(Nolabel, Some inner)];
    } when p.prim_name = "%identity" -> identity inner
  | _ -> expr

let escape text =
  let out = Buffer.create (String.length text) in
  String.iter (function
    | '&' -> Buffer.add_string out "&amp;"
    | '<' -> Buffer.add_string out "&lt;"
    | '>' -> Buffer.add_string out "&gt;"
    | '"' -> Buffer.add_string out "&quot;"
    | '\'' -> Buffer.add_string out "&#x27;"
    | c -> Buffer.add_char out c) text;
  Buffer.contents out

let void_tag tag = List.mem tag
  ["area"; "base"; "br"; "col"; "embed"; "hr"; "img"; "input";
   "link"; "meta"; "param"; "source"; "track"; "wbr"]

let native expr =
  match expr.exp_desc with
  | Texp_apply {
      funct = {exp_desc = Texp_ident (Path.Pdot (parent, _, _), _, desc)};
      args = [(Nolabel, Some tag); (Nolabel, Some props)];
      transformed_jsx = true;
    } when marked "resx.html" desc.val_attributes ->
    let tag = match tag.exp_desc with
      | Texp_constant (Const_string (tag, _)) when not (void_tag tag) -> tag
      | _ -> raise Unsupported
    in
    let fields = match props.exp_desc with
      | Texp_record {fields; extended_expression = None} -> fields
      | _ -> raise Unsupported
    in
    let opening = Buffer.create 64 in
    Buffer.add_string opening ("<" ^ tag);
    let children = ref None in
    Array.iter (fun (label, definition, _) ->
      let value = match definition with
        | Kept _ -> raise Unsupported
        | Overridden (_, value) ->
          if label.Types.lbl_optional then match value.exp_desc with
            | Texp_construct (_, {cstr_name = "None"}, []) -> None
            | Texp_construct (_, {cstr_name = "Some"}, [inner]) -> Some inner
            | Texp_apply {funct = {exp_desc = Texp_ident (_, _, {val_kind = Val_prim p})};
                args = [(Nolabel, Some inner)]}
              when label.lbl_name = "children" && p.prim_name = "%identity" -> Some inner
            | _ -> raise Unsupported
          else Some value
      in
      match value with
      | None -> ()
      | Some value ->
        let name = label.Types.lbl_name in
        if name = "children" then children := Some value
        else match name, (identity value).exp_desc with
        | ("className" | "id" | "title"), Texp_constant (Const_string (text, _)) when not (String.contains text '\\') ->
          if name <> "className" || text <> "" then
            Buffer.add_string opening
              (" " ^ (if name = "className" then "class" else name) ^ "=\"" ^ escape text ^ "\"")
        | _ -> raise Unsupported) fields;
    Buffer.add_char opening '>';
    (parent, Buffer.contents opening, !children, "</" ^ tag ^ ">")
  | _ -> raise Unsupported

let rec pieces expr =
  try
    let _, before, children, after = native expr in
    Static before :: (match children with None -> [] | Some e -> child_pieces e) @ [Static after]
  with Unsupported -> [Child expr]
and child_pieces expr =
  match (identity expr).exp_desc with
  | Texp_constant (Const_string (text, _)) when not (String.contains text '\\') -> [Static (escape text)]
  | Texp_array items -> List.concat_map child_pieces items
  | _ -> pieces expr

let coalesce pieces =
  List.fold_left (fun acc piece -> match acc, piece with
    | Static a :: rest, Static b -> Static (a ^ b) :: rest
    | _ -> piece :: acc) [] pieces |> List.rev

let transform structure =
  let generated = ref [] in
  let serial = ref 0 in
  let default = Tast_mapper.default in
  let depth = ref 0 in
  let mapper = {default with expr = (fun self expr ->
    let outermost = !depth = 0 in
    incr depth;
    let result = try
      let parent, _, _, _ = native expr in
      let plan = coalesce (pieces expr) in
      let loc = expr.exp_loc in
      let lid txt = {Location.txt; loc} in
      let runtime name = Longident.Ldot (longident parent, name) in
      let ident name = Ast_helper.Exp.ident ~loc (lid (Longident.Lident name)) in
      let call name args = Ast_helper.Exp.apply ~loc
        (Ast_helper.Exp.ident ~loc (lid (runtime name)))
        (List.map (fun e -> (Nolabel, e)) args) in
      let holes = ref [] in
      let statements = List.map (function
        | Static text -> call "templateStatic"
            [ident "output"; Ast_helper.Exp.constant ~loc (Pconst_string (text, None))]
        | Child value ->
          let index = List.length !holes in
          holes := self.expr self value :: !holes;
          call "templateChild" [ident "output"; ident "_context";
            call "templateValue" [ident "_values"; Ast_helper.Exp.constant ~loc (Pconst_integer (string_of_int index, None))]]) plan in
      let body = match List.rev statements with
        | last :: rest -> List.fold_left (fun body first -> Ast_helper.Exp.sequence ~loc first body) last rest
        | [] -> raise Unsupported in
      let fn = List.fold_right (fun (name, arity) body ->
        Ast_helper.Exp.fun_ ~loc ~arity Nolabel None
          (Ast_helper.Pat.var ~loc (lid name)) body)
        [("output", Some 3); ("_context", None); ("_values", None)] body in
      let bindings, _ = Typecore.type_binding ~context:None expr.exp_env Nonrecursive
        [Ast_helper.Vb.mk ~loc (Ast_helper.Pat.any ~loc ()) fn] None in
      let emitter = (List.hd bindings).vb_expr in
      let name = "resxTemplate" ^ string_of_int !serial in
      incr serial;
      let id = Ident.create name in
      let desc = {Types.val_type = emitter.exp_type; val_kind = Val_reg;
        val_loc = loc; val_attributes = []} in
      let binding = {vb_pat = {pat_desc = Tpat_var (id, lid name); pat_loc = loc;
          pat_extra = []; pat_type = emitter.exp_type; pat_env = expr.exp_env; pat_attributes = []};
        vb_expr = emitter; vb_attributes = []; vb_loc = loc} in
      generated := binding :: !generated;
      let fnref = {emitter with exp_desc = Texp_ident (Path.Pident id, lid (Longident.Lident name), desc)} in
      let make_lid = runtime "template" in
      let make_path, make_desc = Env.lookup_value ~loc make_lid expr.exp_env in
      let make = {expr with exp_desc = Texp_ident (make_path, lid make_lid, make_desc);
        exp_type = make_desc.val_type; exp_extra = []; exp_attributes = []} in
      let values = {expr with exp_desc = Texp_array (List.rev !holes);
        exp_type = Predef.type_array expr.exp_type; exp_extra = []; exp_attributes = []} in
      if Sys.getenv_opt "RESX_COMPILER_REPORT" = Some "1" then
        Printf.eprintf "[resx] %s:%d: template with %d dynamic slots\n%!"
          loc.loc_start.pos_fname loc.loc_start.pos_lnum (List.length !holes);
      {expr with exp_desc = Texp_apply {funct = make;
        args = [(Nolabel, Some fnref); (Nolabel, Some values)]; partial = false;
        transformed_jsx = false}}
    with Unsupported -> default.expr self expr in
    decr depth;
    if outermost then (
      let bindings = List.rev !generated in
      generated := [];
      List.fold_right (fun binding body ->
        {body with exp_desc = Texp_let (Nonrecursive, [binding], body)}) bindings result
    ) else result)} in
  mapper.structure mapper structure

let implementation structure =
  if Sys.getenv_opt "RESX_HTML_COMPILER" = Some "1" then transform structure else structure
