// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Js_exn = require("rescript/lib/js/js_exn.js");
var Htmx$ResX = require("rescript-x/src/Htmx.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var HtmxHandler = require("./HtmxHandler.js");
var ErrorMessage = require("./ErrorMessage.js");
var Handlers$ResX = require("rescript-x/src/Handlers.js");
var ResX__React$ResX = require("rescript-x/src/ResX__React.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");
var ResX__ReactDOM$ResX = require("rescript-x/src/ResX__ReactDOM.js");
var FormDataHelpers$ResX = require("rescript-x/src/FormDataHelpers.js");

function myVariantFromString(a) {
  if (!(!(a instanceof File) && typeof a !== "string") && typeof a === "string") {
    switch (a) {
      case "one" :
          return {
                  TAG: "Ok",
                  _0: "One"
                };
      case "two" :
          return {
                  TAG: "Ok",
                  _0: "Two"
                };
      default:
        
    }
  }
  return {
          TAG: "Error",
          _0: "Unknown value: \"" + String(a) + "\""
        };
}

var onButtonBlick = Handlers$ResX.hxPost(HtmxHandler.handler, "/button-click", (async function (param) {
        try {
          var formData = await param.request.formData();
          var firstName = FormDataHelpers$ResX.expectString(formData, "firstName", undefined);
          var lastName = FormDataHelpers$ResX.expectString(formData, "lastName", undefined);
          FormDataHelpers$ResX.expectCustom(formData, "myVariant", myVariantFromString);
          return ResX__ReactDOM$ResX.jsx("span", {
                      children: "Hi " + firstName + " " + lastName + "!"
                    });
        }
        catch (raw_exn){
          var exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
          if (exn.RE_EXN_ID === Js_exn.$$Error) {
            return ResX__React$ResX.jsx(ErrorMessage.make, {
                        message: "Something went wrong..."
                      });
          }
          throw exn;
        }
      }));

function Hello(props) {
  return ResX__ReactDOM$ResX.jsxs("form", {
              children: [
                ResX__ReactDOM$ResX.jsx("button", {
                      children: "Hello " + props.name,
                      "hx-post": Caml_option.some(onButtonBlick),
                      "hx-swap": Caml_option.some(Htmx$ResX.Swap.make("innerHTML", "Transition"))
                    }),
                ResX__ReactDOM$ResX.jsx("input", {
                      name: "firstName",
                      type: "text",
                      value: ""
                    }),
                ResX__ReactDOM$ResX.jsx("input", {
                      name: "lastName",
                      type: "text",
                      value: ""
                    })
              ],
              action: "post"
            });
}

var make = Hello;

exports.myVariantFromString = myVariantFromString;
exports.onButtonBlick = onButtonBlick;
exports.make = make;
/* onButtonBlick Not a pure module */
