type t

@unboxed type formDataValue = String(string) | File(Js.File.t)
@unboxed type formDataValueResult = | ...formDataValue | @as(null) Null

let getString: (t, string) => option<string>
let getInt: (t, string) => option<int>
let getFloat: (t, string) => option<float>
let getBool: (t, string) => option<bool>
let getCustom: (
  t,
  string,
  ~decoder: formDataValueResult => result<'value, 'error>,
) => result<'value, 'error>

let expectCustom: (t, string, ~decoder: formDataValueResult => result<'value, string>) => 'value
let expectString: (t, string, ~message: string=?) => string
let expectInt: (t, string, ~message: string=?) => int
let expectFloat: (t, string, ~message: string=?) => float
let expectBool: (t, string, ~message: string=?) => bool

let getStringArray: (t, string) => array<string>
let getIntArray: (t, string) => array<int>
let getFloatArray: (t, string) => array<float>
let getBoolArray: (t, string) => array<bool>
