// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Buntest = require("bun:test");
var TestUtils$ResX = require("./TestUtils.js");
var ResX__React$ResX = require("../src/ResX__React.js");
var RenderInHead$ResX = require("../src/RenderInHead.js");
var ResX__ReactDOM$ResX = require("../src/ResX__ReactDOM.js");
var RequestController$ResX = require("../src/RequestController.js");

Buntest.describe("rendering", (function () {
        Buntest.test("render in head", (async function () {
                var text = await TestUtils$ResX.getContentInBody(function (renderConfig) {
                      return ResX__React$ResX.jsx(TestUtils$ResX.Html.make, {
                                  children: ResX__React$ResX.jsx(RenderInHead$ResX.make, {
                                        children: ResX__ReactDOM$ResX.jsx("meta", {
                                              content: "test",
                                              name: "test"
                                            }),
                                        requestController: renderConfig.requestController
                                      })
                                });
                    });
                Buntest.expect(text).toBe("<!DOCTYPE html><html><head><meta content=\"test\" name=\"test\"/></head><body></body></html>");
              }), undefined);
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
                              return ResX__React$ResX.jsx(TestUtils$ResX.Html.make, {
                                          children: ResX__ReactDOM$ResX.jsx("div", {})
                                        });
                            });
                        Buntest.expect(text).toBe("<html><head></head><body><div></div></body></html>");
                      }), undefined);
              }));
      }));

/*  Not a pure module */
