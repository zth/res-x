// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Htmx = require("res-x/src/Htmx.js");
var Js_exn = require("rescript/lib/js/js_exn.js");
var $$FormData = require("res-x/src/FormData.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var HtmxHandler = require("./HtmxHandler.js");
var ResX__React = require("res-x/src/ResX__React.js");
var ErrorMessage = require("./ErrorMessage.js");
var ResX__Handlers = require("res-x/src/ResX__Handlers.js");
var ResX__ReactDOM = require("res-x/src/ResX__ReactDOM.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");

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

var onButtonBlick = ResX__Handlers.post(HtmxHandler.handler, "/button-click", (async function (param) {
        try {
          var formData = await param.request.formData();
          var firstName = $$FormData.expectString(formData, "firstName", undefined);
          var lastName = $$FormData.expectString(formData, "lastName", undefined);
          $$FormData.expectCustom(formData, "myVariant", myVariantFromString);
          return ResX__ReactDOM.jsx("span", {
                      children: "Hi " + firstName + " " + lastName + "!"
                    });
        }
        catch (raw_exn){
          var exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
          if (exn.RE_EXN_ID === Js_exn.$$Error) {
            return ResX__React.jsx(ErrorMessage.make, {
                        message: "Something went wrong..."
                      });
          }
          throw exn;
        }
      }));

function Hello(props) {
  return ResX__ReactDOM.jsxs("form", {
              children: [
                ResX__ReactDOM.jsx("button", {
                      children: "Hello " + props.name,
                      "hx-post": Caml_option.some(onButtonBlick),
                      "hx-swap": Caml_option.some(Htmx.Swap.make("innerHTML", "Transition"))
                    }),
                ResX__ReactDOM.jsx("input", {
                      name: "firstName",
                      type: "text",
                      value: ""
                    }),
                ResX__ReactDOM.jsx("input", {
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
