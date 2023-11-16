// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Core__Int = require("@rescript/core/src/Core__Int.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Core__Array = require("@rescript/core/src/Core__Array.js");
var Core__Float = require("@rescript/core/src/Core__Float.js");
var Core__Option = require("@rescript/core/src/Core__Option.js");
var RescriptCore = require("@rescript/core/src/RescriptCore.js");

function getOrRaise(opt, name, expectedType, message) {
  if (opt !== undefined) {
    return Caml_option.valFromOption(opt);
  } else {
    return RescriptCore.panic(message !== undefined ? message : "Expected \"" + name + "\" to be " + expectedType + ", but got something else.");
  }
}

function getString(t, name) {
  var s = t.get(name);
  if (!(s instanceof File) && typeof s !== "string" || typeof s !== "string") {
    return ;
  } else {
    return s;
  }
}

function getInt(t, name) {
  return Core__Option.flatMap(getString(t, name), (function (s) {
                return Core__Int.fromString(undefined, s);
              }));
}

function getFloat(t, name) {
  return Core__Option.flatMap(getString(t, name), (function (s) {
                return Core__Float.fromString(s);
              }));
}

function getBool(t, name) {
  var match = t.get(name);
  if (!(match instanceof File) && typeof match !== "string") {
    return ;
  }
  if (typeof match !== "string") {
    return ;
  }
  switch (match) {
    case "false" :
        return false;
    case "true" :
        return true;
    default:
      return ;
  }
}

function getStringArray(t, name) {
  return Core__Array.keepSome(t.getAll(name).map(function (v) {
                  if (typeof v === "string") {
                    return v;
                  }
                  
                }));
}

function getIntArray(t, name) {
  return Core__Array.keepSome(t.getAll(name).map(function (v) {
                  if (typeof v === "string") {
                    return Core__Int.fromString(undefined, v);
                  }
                  
                }));
}

function getFloatArray(t, name) {
  return Core__Array.keepSome(t.getAll(name).map(function (v) {
                  if (typeof v === "string") {
                    return Core__Float.fromString(v);
                  }
                  
                }));
}

function getBoolArray(t, name) {
  return Core__Array.keepSome(t.getAll(name).map(function (v) {
                  if (typeof v !== "string") {
                    return ;
                  }
                  switch (v) {
                    case "false" :
                        return false;
                    case "true" :
                        return true;
                    default:
                      return ;
                  }
                }));
}

function getCustom(t, name, decoder) {
  return decoder(t.get(name));
}

function expectCustom(t, name, decoder) {
  var message = getCustom(t, name, decoder);
  if (message.TAG === "Ok") {
    return message._0;
  } else {
    return RescriptCore.panic(message._0);
  }
}

function expectString(t, name, message) {
  return getOrRaise(getString(t, name), name, "string", message);
}

function expectInt(t, name, message) {
  return getOrRaise(getInt(t, name), name, "int", message);
}

function expectFloat(t, name, message) {
  return getOrRaise(getFloat(t, name), name, "float", message);
}

function expectBool(t, name, message) {
  return getOrRaise(getBool(t, name), name, "bool", message);
}

function expectCheckbox(t, name) {
  return expectCustom(t, name, (function (res) {
                if (!(res instanceof File) && typeof res !== "string" || !(typeof res === "string" && res === "on")) {
                  return {
                          TAG: "Ok",
                          _0: false
                        };
                } else {
                  return {
                          TAG: "Ok",
                          _0: true
                        };
                }
              }));
}

function expectDate(t, name) {
  return expectCustom(t, name, (function (res) {
                if (!(res instanceof File) && typeof res !== "string") {
                  return {
                          TAG: "Error",
                          _0: "Invalid date."
                        };
                }
                if (typeof res !== "string") {
                  return {
                          TAG: "Error",
                          _0: "Invalid date."
                        };
                }
                var date = new Date(res);
                if (isNaN(date.getTime())) {
                  return {
                          TAG: "Error",
                          _0: "Invalid date."
                        };
                } else {
                  return {
                          TAG: "Ok",
                          _0: date
                        };
                }
              }));
}

exports.getOrRaise = getOrRaise;
exports.getString = getString;
exports.getInt = getInt;
exports.getFloat = getFloat;
exports.getBool = getBool;
exports.getStringArray = getStringArray;
exports.getIntArray = getIntArray;
exports.getFloatArray = getFloatArray;
exports.getBoolArray = getBoolArray;
exports.getCustom = getCustom;
exports.expectCustom = expectCustom;
exports.expectString = expectString;
exports.expectInt = expectInt;
exports.expectFloat = expectFloat;
exports.expectBool = expectBool;
exports.expectCheckbox = expectCheckbox;
exports.expectDate = expectDate;
/* No side effect */
