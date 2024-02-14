// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Buntest = require("bun:test");
var Hjsx$ResX = require("../src/Hjsx.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Handlers$ResX = require("../src/Handlers.js");
var TestUtils$ResX = require("./TestUtils.js");
var RenderInHead$ResX = require("../src/RenderInHead.js");
var RequestController$ResX = require("../src/RequestController.js");

Buntest.describe("rendering", (function () {
        Buntest.describe("render in head", (function () {
                var make = async function (param) {
                  var context = Handlers$ResX.useContext(TestUtils$ResX.Handler.handler);
                  return Hjsx$ResX.jsx(RenderInHead$ResX.make, {
                              children: Hjsx$ResX.Elements.jsx("meta", {
                                    content: "test",
                                    name: "test"
                                  }),
                              requestController: context.requestController
                            });
                };
                var Rendering$dottest = make;
                Buntest.test("render in head with async component", (async function () {
                        var text = await TestUtils$ResX.getContentInBody(function (_renderConfig) {
                              return Hjsx$ResX.jsx(TestUtils$ResX.Html.make, {
                                          children: Hjsx$ResX.jsx(Rendering$dottest, {})
                                        });
                            });
                        Buntest.expect(text).toBe("<!DOCTYPE html><html><head><meta content=\"test\" name=\"test\"/></head><body></body></html>");
                      }), undefined);
                Buntest.test("render in head", (async function () {
                        var text = await TestUtils$ResX.getContentInBody(function (renderConfig) {
                              return Hjsx$ResX.jsx(TestUtils$ResX.Html.make, {
                                          children: Hjsx$ResX.jsx(RenderInHead$ResX.make, {
                                                children: Hjsx$ResX.Elements.jsx("meta", {
                                                      content: "test",
                                                      name: "test"
                                                    }),
                                                requestController: renderConfig.requestController
                                              })
                                        });
                            });
                        Buntest.expect(text).toBe("<!DOCTYPE html><html><head><meta content=\"test\" name=\"test\"/></head><body></body></html>");
                      }), undefined);
              }));
        Buntest.describe("DOCTYPE", (function () {
                Buntest.test("change DOCTYPE", (async function () {
                        var text = await TestUtils$ResX.getContentInBody(function (renderConfig) {
                              RequestController$ResX.setDocHeader(renderConfig.requestController, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
                              return null;
                            });
                        Buntest.expect(text).toBe("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
                      }), undefined);
                Buntest.test("remove DOCTYPE", (async function () {
                        var text = await TestUtils$ResX.getContentInBody(function (renderConfig) {
                              RequestController$ResX.setDocHeader(renderConfig.requestController, undefined);
                              return Hjsx$ResX.jsx(TestUtils$ResX.Html.make, {
                                          children: Hjsx$ResX.Elements.jsx("div", {})
                                        });
                            });
                        Buntest.expect(text).toBe("<html><head></head><body><div></div></body></html>");
                      }), undefined);
              }));
        Buntest.describe("Security", (function () {
                Buntest.test("title segments are escaped", (async function () {
                        var text = await TestUtils$ResX.getContentInBody(function (renderConfig) {
                              RequestController$ResX.appendTitleSegment(renderConfig.requestController, "</title></head>");
                              return Hjsx$ResX.jsx(TestUtils$ResX.Html.make, {
                                          children: Hjsx$ResX.Elements.jsx("div", {})
                                        });
                            });
                        Buntest.expect(text).toBe("<!DOCTYPE html><html><head><title>&lt;/title&gt;&lt;/head&gt;</title></head><body><div></div></body></html>");
                      }), undefined);
              }));
        Buntest.describe("hooks", (function () {
                Buntest.test("onBeforeSendResponse change status", (async function () {
                        var response = await TestUtils$ResX.getResponse((function (_renderConfig) {
                                return Hjsx$ResX.jsx(TestUtils$ResX.Html.make, {
                                            children: Hjsx$ResX.Elements.jsx("div", {
                                                  children: "Hi!"
                                                })
                                          });
                              }), (async function (config) {
                                return new Response(await config.response.text(), {
                                            status: 400,
                                            headers: config.response.headers.toJSON()
                                          });
                              }), undefined);
                        var status = response.status;
                        var text = await response.text();
                        Buntest.expect(status).toBe(400);
                        Buntest.expect(text).toBe("<!DOCTYPE html><html><head></head><body><div>Hi!</div></body></html>");
                      }), undefined);
                Buntest.test("onBeforeSendResponse set header", (async function () {
                        var response = await TestUtils$ResX.getResponse((function (_renderConfig) {
                                return Hjsx$ResX.jsx(TestUtils$ResX.Html.make, {
                                            children: Hjsx$ResX.Elements.jsx("div", {
                                                  children: "Hi!"
                                                })
                                          });
                              }), (async function (config) {
                                config.response.headers.set("x-user-id", "1");
                                return config.response;
                              }), undefined);
                        var userIdHeader = response.headers.get("x-user-id");
                        Buntest.expect((userIdHeader == null) ? undefined : Caml_option.some(userIdHeader)).toBe("1");
                      }), undefined);
              }));
      }));

/*  Not a pure module */
