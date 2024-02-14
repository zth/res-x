// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Js_exn = require("rescript/lib/js/js_exn.js");
var Hjsx$ResX = require("rescript-x/src/Hjsx.js");
var Htmx$ResX = require("rescript-x/src/Htmx.js");
var ResXAssets = require("./__generated__/ResXAssets.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Client$ResX = require("rescript-x/src/Client.js");
var HtmxHandler = require("./HtmxHandler.js");
var Core__Option = require("@rescript/core/src/Core__Option.js");
var Handlers$ResX = require("rescript-x/src/Handlers.js");
var FailingComponent = require("./FailingComponent.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");
var ErrorBoundary$ResX = require("rescript-x/src/ErrorBoundary.js");
var FormDataHelpers$ResX = require("rescript-x/src/FormDataHelpers.js");

var onForm = Handlers$ResX.hxPost(HtmxHandler.handler, "/user-single", (async function (param) {
        var formData = await param.request.formData();
        try {
          var name = FormDataHelpers$ResX.expectString(formData, "name", undefined);
          var active = FormDataHelpers$ResX.expectCheckbox(formData, "active");
          return Hjsx$ResX.Elements.jsx("div", {
                      children: "Some user " + name + " is " + (
                        active ? "active" : "not active"
                      )
                    });
        }
        catch (raw_err){
          var err = Caml_js_exceptions.internalToOCamlException(raw_err);
          if (err.RE_EXN_ID === Js_exn.$$Error) {
            console.error(err._1);
            return Hjsx$ResX.Elements.jsx("div", {
                        children: "Failed"
                      });
          }
          throw err;
        }
      }));

function UserPage(props) {
  var ctx = HtmxHandler.useContext();
  ctx.headers.set("Content-Type", "text/html");
  return Hjsx$ResX.Elements.jsxs("div", {
              children: [
                Hjsx$ResX.Elements.jsxs("form", {
                      children: [
                        Hjsx$ResX.Elements.jsx("img", {
                              src: ResXAssets.assets.images__test_img_jpeg
                            }),
                        Hjsx$ResX.Elements.jsx("div", {
                              children: Hjsx$ResX.Elements.jsx("div", {
                                    children: "User 123 3333 " + props.userId,
                                    className: "text-2xl bg-slate-200 text-gray-500"
                                  }),
                              id: "user-single"
                            }),
                        Hjsx$ResX.Elements.jsx("div", {
                              children: Hjsx$ResX.Elements.jsx("input", {
                                    className: "p-2",
                                    name: "name",
                                    type: "text"
                                  }),
                              className: "p-2"
                            }),
                        Hjsx$ResX.Elements.jsx("div", {
                              children: Hjsx$ResX.Elements.jsx("input", {
                                    className: "invalid:border-green-400 border border-gray-500",
                                    name: "lastName",
                                    required: true,
                                    type: "text",
                                    "resx-validity-message": Caml_option.some(Client$ResX.ValidityMessage.make({
                                              valueMissing: "Yo, you need to fill this in!"
                                            }))
                                  }),
                              className: "p-2"
                            }),
                        Hjsx$ResX.Elements.jsx("div", {
                              children: Hjsx$ResX.Elements.jsx("input", {
                                    name: "active",
                                    type: "checkbox"
                                  }),
                              className: "p-2"
                            }),
                        Hjsx$ResX.Elements.jsxs("div", {
                              children: [
                                Hjsx$ResX.Elements.jsxs("label", {
                                      children: [
                                        Hjsx$ResX.Elements.jsx("input", {
                                              name: "status",
                                              type: "radio",
                                              value: "on"
                                            }),
                                        "On"
                                      ]
                                    }),
                                Hjsx$ResX.Elements.jsxs("label", {
                                      children: [
                                        Hjsx$ResX.Elements.jsx("input", {
                                              name: "status",
                                              type: "radio",
                                              value: "off"
                                            }),
                                        "Off"
                                      ]
                                    })
                              ],
                              className: "p-2"
                            }),
                        Hjsx$ResX.Elements.jsx("div", {
                              children: Hjsx$ResX.Elements.jsx("textarea", {
                                    name: "description"
                                  }),
                              className: "p-2"
                            }),
                        Hjsx$ResX.Elements.jsx("div", {
                              children: Hjsx$ResX.Elements.jsx("button", {
                                    children: "Submit form",
                                    id: "test",
                                    "resx-onclick": Caml_option.some(Client$ResX.Actions.make([{
                                                kind: "ToggleClass",
                                                target: "This",
                                                className: "text-xl"
                                              }]))
                                  }),
                              className: "p-2"
                            }),
                        Hjsx$ResX.jsx(ErrorBoundary$ResX.make, {
                              children: Hjsx$ResX.jsx(FailingComponent.make, {}),
                              renderError: (function (err) {
                                  return Hjsx$ResX.Elements.jsx("div", {
                                              children: "Oops, failed! " + Core__Option.getOr(err.message, "-")
                                            });
                                })
                            })
                      ],
                      "hx-post": Caml_option.some(onForm),
                      "hx-swap": Caml_option.some(Htmx$ResX.Swap.make("innerHTML", undefined)),
                      "hx-target": Caml_option.some(Htmx$ResX.Target.make({
                                TAG: "CssSelector",
                                _0: "#user-single"
                              }))
                    }),
                props.innerContent
              ],
              className: "p-8"
            });
}

var make = UserPage;

exports.onForm = onForm;
exports.make = make;
/* onForm Not a pure module */
