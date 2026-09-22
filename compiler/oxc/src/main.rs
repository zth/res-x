use oxc_allocator::Allocator;
use oxc_ast::{AstKind, ast::*};
use oxc_ast_visit::{Visit, walk};
use oxc_parser::Parser;
use oxc_semantic::{Semantic, SemanticBuilder};
use oxc_span::{GetSpan, SourceType, Span};
use oxc_syntax::symbol::SymbolId;
use serde::{Deserialize, Serialize};
use std::{
    collections::{HashMap, HashSet},
    io::{self, BufRead, Write},
};

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct Request {
    code: String,
    filename: String,
    runtime_specifiers: Vec<String>,
}
#[derive(Serialize)]
struct Edit {
    start: u32,
    end: u32,
    text: String,
}
#[derive(Default, Serialize)]
struct Response {
    edits: Vec<Edit>,
    suffix: String,
    templates: usize,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

fn string<'a>(expr: &'a Expression<'_>) -> Option<&'a str> {
    if let Expression::StringLiteral(s) = expr {
        if !s.lone_surrogates {
            return Some(s.value.as_str());
        }
    }
    None
}
fn symbol(id: &IdentifierReference<'_>, semantic: &Semantic<'_>) -> Option<SymbolId> {
    semantic
        .scoping()
        .get_reference(id.reference_id.get()?)
        .symbol_id()
}
fn escape(value: &str) -> String {
    let mut out = String::with_capacity(value.len());
    for c in value.chars() {
        match c {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            '\'' => out.push_str("&#x27;"),
            _ => out.push(c),
        }
    }
    out
}
fn quote(s: &str) -> String {
    serde_json::to_string(s).expect("strings serialize")
}

// Only imports from paths approved by the adapter, with scope-resolved bindings.
struct Imports<'s, 'a> {
    semantic: &'s Semantic<'a>,
    approved: &'s [String],
    bindings: HashMap<SymbolId, String>,
}
impl<'a> Visit<'a> for Imports<'_, 'a> {
    fn visit_variable_declarator(&mut self, decl: &VariableDeclarator<'a>) {
        if let (BindingPattern::BindingIdentifier(id), Some(Expression::CallExpression(call))) =
            (&decl.id, &decl.init)
            && let Expression::Identifier(require) = &call.callee
            && require.name == "require"
            && symbol(require, self.semantic).is_none()
            && call.arguments.len() == 1
            && !call.optional
            && let Some(Expression::StringLiteral(path)) = call.arguments[0].as_expression()
            && self.approved.iter().any(|s| s == path.value.as_str())
            && let Some(sid) = id.symbol_id.get()
            && self.semantic.scoping().symbol_scope_id(sid)
                == self.semantic.scoping().root_scope_id()
        {
            self.bindings.insert(sid, id.name.to_string());
        }
        walk::walk_variable_declarator(self, decl);
    }
    fn visit_import_declaration(&mut self, decl: &ImportDeclaration<'a>) {
        if self
            .approved
            .iter()
            .any(|s| s == decl.source.value.as_str())
            && decl.phase.is_none()
            && let Some(specifiers) = &decl.specifiers
        {
            for spec in specifiers {
                if let ImportDeclarationSpecifier::ImportNamespaceSpecifier(spec) = spec
                    && let Some(sid) = spec.local.symbol_id.get()
                {
                    self.bindings.insert(sid, spec.local.name.to_string());
                }
            }
        }
    }
}
fn safe_binding(semantic: &Semantic<'_>, sid: SymbolId) -> bool {
    // Reject mutation and escapes, including properties being assigned/deleted
    // or the namespace being passed to unknown code. Normal factory calls stay.
    semantic.scoping().get_resolved_references(sid).all(|reference| {
        if reference.is_write() { return false; }
        let nodes = semantic.nodes();
        let mut id = nodes.parent_id(reference.node_id());
        let AstKind::StaticMemberExpression(member) = nodes.kind(id) else { return false; };
        if member.optional { return false; }
        let property = if member.property.name == "Elements" {
            id = nodes.parent_id(id);
            let AstKind::StaticMemberExpression(member) = nodes.kind(id) else { return false; };
            if member.optional { return false; }
            member.property.name.as_str()
        } else { member.property.name.as_str() };
        if property == "jsxFragment" { return true; }
        if !matches!(property, "jsx" | "jsxs" | "template" | "templateStatic" | "templateChild" | "dangerouslyOutputUnescapedContent") { return false; }
        matches!(nodes.parent_kind(id), AstKind::CallExpression(call) if call.callee.span() == nodes.kind(id).span() && !call.optional)
    })
}

enum Piece<'a> {
    Static(String),
    Child(&'a Expression<'a>),
}
struct Plan<'a> {
    runtime: String,
    pieces: Vec<Piece<'a>>,
}
struct Transform<'s, 'a> {
    source: &'s str,
    semantic: &'s Semantic<'a>,
    bindings: HashMap<SymbolId, String>,
    edits: Vec<Edit>,
    helpers: String,
    serial: usize,
    templates: usize,
}
impl<'a> Transform<'_, 'a> {
    fn native(
        &self,
        expr: &'a Expression<'a>,
    ) -> Option<(String, String, Option<&'a Expression<'a>>, String)> {
        let Expression::CallExpression(call) = expr else {
            return None;
        };
        if call.optional || call.arguments.len() != 2 {
            return None;
        }
        let Expression::StaticMemberExpression(factory) = &call.callee else {
            return None;
        };
        if factory.optional || !matches!(factory.property.name.as_str(), "jsx" | "jsxs") {
            return None;
        }
        let Expression::StaticMemberExpression(elements) = &factory.object else {
            return None;
        };
        if elements.optional || elements.property.name != "Elements" {
            return None;
        }
        let Expression::Identifier(id) = &elements.object else {
            return None;
        };
        let runtime = self.bindings.get(&symbol(id, self.semantic)?)?.clone();
        let tag = string(call.arguments[0].as_expression()?)?;
        if tag.is_empty()
            || !tag.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-')
            || matches!(
                tag,
                "area"
                    | "base"
                    | "br"
                    | "col"
                    | "embed"
                    | "hr"
                    | "img"
                    | "input"
                    | "link"
                    | "meta"
                    | "param"
                    | "source"
                    | "track"
                    | "wbr"
            )
        {
            return None;
        }
        let Expression::ObjectExpression(props) = call.arguments[1].as_expression()? else {
            return None;
        };
        let mut before = format!("<{tag}");
        let mut children = None;
        let mut seen = HashSet::new();
        for property in &props.properties {
            let ObjectPropertyKind::ObjectProperty(property) = property else {
                return None;
            };
            if property.computed || property.method || property.kind != PropertyKind::Init {
                return None;
            }
            let key = match &property.key {
                PropertyKey::StaticIdentifier(id) => id.name.as_str(),
                PropertyKey::StringLiteral(s) if !s.lone_surrogates => s.value.as_str(),
                _ => return None,
            };
            if !seen.insert(key) {
                return None;
            }
            match key {
                "children" => children = Some(&property.value),
                "className" | "id" | "title" => {
                    let value = string(&property.value)?;
                    if key != "className" || !value.is_empty() {
                        before.push_str(&format!(
                            " {}=\"{}\"",
                            if key == "className" { "class" } else { key },
                            escape(value)
                        ));
                    }
                }
                _ => return None,
            }
        }
        before.push('>');
        Some((runtime, before, children, format!("</{tag}>")))
    }
    fn pieces(&self, expr: &'a Expression<'a>, out: &mut Vec<Piece<'a>>) {
        if let Some(value) = string(expr) {
            out.push(Piece::Static(escape(value)));
        } else if let Expression::ArrayExpression(array) = expr {
            // Spread iterators and holes stay on the existing renderer path.
            if array.elements.iter().all(|e| e.as_expression().is_some()) {
                for child in &array.elements {
                    self.pieces(child.as_expression().unwrap(), out);
                }
            } else {
                out.push(Piece::Child(expr));
            }
        } else if let Some((_, before, children, after)) = self.native(expr) {
            out.push(Piece::Static(before));
            if let Some(children) = children {
                self.pieces(children, out);
            }
            out.push(Piece::Static(after));
        } else {
            out.push(Piece::Child(expr));
        }
    }
    fn plan(&self, expr: &'a Expression<'a>) -> Option<Plan<'a>> {
        let (runtime, _, _, _) = self.native(expr)?;
        let mut pieces = Vec::new();
        self.pieces(expr, &mut pieces);
        let mut combined = Vec::new();
        for piece in pieces {
            match (combined.last_mut(), piece) {
                (Some(Piece::Static(a)), Piece::Static(b)) => a.push_str(&b),
                (_, p) => combined.push(p),
            }
        }
        Some(Plan {
            runtime,
            pieces: combined,
        })
    }
    fn render_child(&mut self, expr: &'a Expression<'a>) -> String {
        let outer = std::mem::take(&mut self.edits);
        self.visit_expression(expr);
        let nested = std::mem::replace(&mut self.edits, outer);
        apply(self.source, expr.span(), &nested)
    }
}
impl<'a> Visit<'a> for Transform<'_, 'a> {
    fn visit_expression(&mut self, expr: &Expression<'a>) {
        let expr = self.alloc(expr);
        if let Some(plan) = self.plan(expr) {
            let name = loop {
                let name = format!("__resxWriter{}", self.serial);
                self.serial += 1;
                if !self.source.contains(&name) {
                    break name;
                }
            };
            let mut values = Vec::new();
            let runtime = format!("{}.Elements", plan.runtime);
            let mut body = String::new();
            for piece in plan.pieces {
                match piece {
                    Piece::Static(text) => body.push_str(&format!(
                        "{runtime}.templateStatic(output, {});\n",
                        quote(&text)
                    )),
                    Piece::Child(expr) => {
                        let index = values.len();
                        values.push(format!("({})", self.render_child(expr)));
                        body.push_str(&format!(
                            "{runtime}.templateChild(output, context, values[{index}]);\n"
                        ));
                    }
                }
            }
            self.helpers.push_str(&format!(
                "\nfunction {name}(output, context, values) {{\n{body}}}\n"
            ));
            self.edits.push(Edit {
                start: expr.span().start,
                end: expr.span().end,
                text: format!("{runtime}.template({name}, [{}])", values.join(", ")),
            });
            self.templates += 1;
        } else {
            walk::walk_expression(self, expr);
        }
    }
}
fn apply(source: &str, span: Span, edits: &[Edit]) -> String {
    let mut ordered: Vec<_> = edits.iter().collect();
    ordered.sort_by_key(|e| e.start);
    let mut out = String::new();
    let mut cursor = span.start as usize;
    for edit in ordered {
        out.push_str(&source[cursor..edit.start as usize]);
        out.push_str(&edit.text);
        cursor = edit.end as usize;
    }
    out.push_str(&source[cursor..span.end as usize]);
    out
}
fn transform(request: Request) -> Result<Response, String> {
    let allocator = Allocator::default();
    let parsed = Parser::new(
        &allocator,
        &request.code,
        SourceType::from_path(&request.filename).map_err(|e| e.to_string())?,
    )
    .parse();
    if !parsed.diagnostics.is_empty() {
        return Err(format!("JavaScript parse error: {:?}", parsed.diagnostics));
    }
    let built = SemanticBuilder::new()
        .with_build_nodes(true)
        .with_check_syntax_error(true)
        .build(&parsed.program);
    if !built.diagnostics.is_empty() {
        return Err(format!(
            "JavaScript semantic error: {:?}",
            built.diagnostics
        ));
    }
    let semantic = built.semantic;
    // Direct eval can mutate an import without a statically visible reference.
    if semantic
        .scoping()
        .scope_flags(semantic.scoping().root_scope_id())
        .contains_direct_eval()
    {
        return Ok(Response::default());
    }
    let mut imports = Imports {
        semantic: &semantic,
        approved: &request.runtime_specifiers,
        bindings: HashMap::new(),
    };
    imports.visit_program(&parsed.program);
    imports
        .bindings
        .retain(|sid, _| safe_binding(&semantic, *sid));
    if imports.bindings.is_empty() {
        return Ok(Response::default());
    }
    let mut visitor = Transform {
        source: &request.code,
        semantic: &semantic,
        bindings: imports.bindings,
        edits: Vec::new(),
        helpers: String::new(),
        serial: 0,
        templates: 0,
    };
    visitor.visit_program(&parsed.program);
    // AST spans are UTF-8 bytes; MagicString edits use UTF-16 offsets. Convert
    // only requested endpoints in one linear pass, without rescanning prefixes.
    let mut positions: Vec<u32> = visitor
        .edits
        .iter()
        .flat_map(|e| [e.start, e.end])
        .collect();
    positions.sort_unstable();
    positions.dedup();
    let mut offsets = HashMap::new();
    let mut next = 0;
    let mut units = 0;
    for (byte, ch) in request
        .code
        .char_indices()
        .chain(std::iter::once((request.code.len(), '\0')))
    {
        while next < positions.len() && positions[next] as usize == byte {
            offsets.insert(positions[next], units);
            next += 1;
        }
        units += ch.len_utf16() as u32;
    }
    for edit in &mut visitor.edits {
        edit.start = offsets[&edit.start];
        edit.end = offsets[&edit.end];
    }
    Ok(Response {
        edits: visitor.edits,
        suffix: visitor.helpers,
        templates: visitor.templates,
        error: None,
    })
}
fn main() {
    let stdin = io::stdin();
    let mut stdout = io::BufWriter::new(io::stdout().lock());
    for line in stdin.lock().lines() {
        let result = line
            .map_err(|e| e.to_string())
            .and_then(|line| serde_json::from_str::<Request>(&line).map_err(|e| e.to_string()))
            .and_then(transform);
        let response = result.unwrap_or_else(|error| Response {
            error: Some(error),
            ..Response::default()
        });
        if serde_json::to_writer(&mut stdout, &response).is_err()
            || writeln!(stdout).is_err()
            || stdout.flush().is_err()
        {
            break;
        }
    }
}
