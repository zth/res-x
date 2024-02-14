// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Buntest = require("bun:test");
var Handlers$ResX = require("../src/Handlers.js");
var TestUtils$ResX = require("./TestUtils.js");

Buntest.describe("Form action handlers", (function () {
        Buntest.test("prefixing of form action handler routes work", (async function () {
                Handlers$ResX.formAction(TestUtils$ResX.Handler.handler, "/test", (async function (param) {
                        return new Response("Test!", undefined);
                      }));
                var response = await TestUtils$ResX.getResponse((function (param) {
                        return "nope";
                      }), undefined, "/_form/test");
                var text = await response.text();
                Buntest.expect(text).toBe("Test!");
              }), undefined);
      }));

/*  Not a pure module */
