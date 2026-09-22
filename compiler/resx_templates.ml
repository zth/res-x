(* Standalone ResX analysis of stock ReScript CMT artifacts.
   Produces ReScript source; never modifies the ReScript compiler. *)
open Asttypes
open Typedtree

exception Unsupported

type piece = Static of string | Child of expression

let marked name attributes =
  List.exists (fun ({Location.txt}, _) -> txt = name) attributes

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


let read_file path =
  let channel = open_in_bin path in
  Fun.protect ~finally:(fun () -> close_in channel)
    (fun () -> really_input_string channel (in_channel_length channel))

let quote text =
  let output = Buffer.create (String.length text + 2) in
  Buffer.add_char output '"';
  String.iter (fun c -> match c with
    | '"' -> Buffer.add_string output "\\\""
    | '\\' -> Buffer.add_string output "\\\\"
    | c when Char.code c < 32 -> Buffer.add_string output (Printf.sprintf "\\u%04x" (Char.code c))
    | c -> Buffer.add_char output c) text;
  Buffer.add_char output '"';
  Buffer.contents output

let generate ~source structure =
  let helpers = ref [] in
  let serial = ref 0 in
  let prefix = "resxHtml" ^ Digest.to_hex (Digest.string source) ^ "Writer" in
  (* Stock ReScript positions use a byte offset for the line start and
     UTF-16 code units for the column, as editor-facing positions do. *)
  let byte_offset (position : Lexing.position) =
    let column = position.pos_cnum - position.pos_bol in
    let rec walk offset units =
      if units = column then offset
      else if units > column || offset >= String.length source then raise Unsupported
      else
        let byte = Char.code source.[offset] in
        let width = if byte >= 0xf0 then 4 else if byte >= 0xe0 then 3 else if byte >= 0xc0 then 2 else 1 in
        walk (offset + width) (units + if width = 4 then 2 else 1)
    in
    if position.pos_bol < 0 || column < 0 then raise Unsupported;
    walk position.pos_bol 0
  in
  let bounds expr =
    let loc = expr.exp_loc in
    let first = byte_offset loc.loc_start and last = byte_offset loc.loc_end in
    if first < 0 || last <= first || last > String.length source then raise Unsupported;
    (first, last)
  in
  let apply first last edits =
    let buffer = Buffer.create (last - first) in
    let cursor = ref first in
    List.sort (fun (a, _, _) (b, _, _) -> compare a b) edits
    |> List.iter (fun (start, finish, text) ->
      if start < !cursor || finish > last then failwith "Overlapping JSX source locations";
      Buffer.add_substring buffer source !cursor (start - !cursor);
      Buffer.add_string buffer text;
      cursor := finish);
    Buffer.add_substring buffer source !cursor (last - !cursor);
    Buffer.contents buffer
  in
  let rec mapper edits : Tast_mapper.mapper =
    let default = Tast_mapper.default in
    {default with expr = (fun self expr ->
      try
        let _, _, _, _ = native expr in
        let first, last = bounds expr in
        let plan = coalesce (pieces expr) in
        List.iter (function Static _ -> () | Child value ->
          let start, finish = bounds value in
          if start < first || finish > last then raise Unsupported) plan;
        let values = ref [] in
        let statements = List.map (function
          | Static text -> "Hjsx.Elements.templateStatic(output, " ^ quote text ^ ")"
          | Child value ->
            let index = List.length !values in
            let start, finish = bounds value in
            let nested = ref [] in
            let visitor = mapper nested in
            ignore (visitor.expr visitor value);
            values := ("(" ^ apply start finish !nested ^ ")") :: !values;
            Printf.sprintf "Hjsx.Elements.templateChild(output, _context, Hjsx.Elements.templateValue(_values, %d))" index) plan in
        let name = prefix ^ string_of_int !serial in
        incr serial;
        helpers := ("%%private(let " ^ name ^ " = (output, _context, _values) => {\n"
          ^ String.concat "\n" statements ^ "\n})\n") :: !helpers;
        edits := (first, last, "{Hjsx.Elements.template(" ^ name ^ ", [" ^ String.concat ", " (List.rev !values) ^ "])}") :: !edits;
        expr
      with Unsupported -> default.expr self expr)}
  in
  let edits = ref [] in
  let visitor = mapper edits in
  ignore (visitor.structure visitor structure);
  String.concat "\n" (List.rev !helpers) ^ apply 0 (String.length source) !edits,
  !serial

let () =
  if Array.length Sys.argv <> 4 then (prerr_endline "Usage: resx-analyze file.cmt source.res output.res"; exit 2);
  let artifact = Sys.argv.(1) and input = Sys.argv.(2) and output = Sys.argv.(3) in
  try
    let source = read_file input in
    let infos = Cmt_format.read_cmt artifact in
    (match infos.cmt_source_digest with
    | Some digest when digest = Digest.string source -> ()
    | _ -> failwith ("Stale compiler artifact: " ^ input));
    let structure = match infos.cmt_annots with
      | Implementation structure -> structure
      | _ -> failwith "Expected a complete implementation CMT" in
    let generated, count = generate ~source structure in
    let channel = open_out_bin output in
    Fun.protect ~finally:(fun () -> close_out channel) (fun () -> output_string channel generated);
    Printf.printf "%d\n" count
  with error -> prerr_endline (Printexc.to_string error); exit 1
