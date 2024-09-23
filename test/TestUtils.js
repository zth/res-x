// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Js_exn = require("rescript/lib/js/js_exn.js");
var Hjsx$ResX = require("../src/Hjsx.js");
var Core__Math = require("@rescript/core/src/Core__Math.js");
var RescriptCore = require("@rescript/core/src/RescriptCore.js");
var Handlers$ResX = require("../src/Handlers.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");

var handler = Handlers$ResX.make((async function (_req) {
        
      }), undefined);

var Handler = {
  handler: handler
};

var currentPortsUsed = new Set();

function getPort() {
  var port;
  while(port === undefined) {
    var assignedPort = Core__Math.Int.random(40000, 50000);
    if (!currentPortsUsed.has(assignedPort)) {
      currentPortsUsed.add(assignedPort);
      port = assignedPort;
    }
    
  };
  var port$1 = port;
  if (port$1 !== undefined) {
    return [
            port$1,
            (function () {
                currentPortsUsed.delete(port$1);
              })
          ];
  } else {
    return [
            -1,
            (function () {
                
              })
          ];
  }
}

function TestUtils$Html(props) {
  return Hjsx$ResX.Elements.jsxs("html", {
              children: [
                Hjsx$ResX.Elements.jsx("head", {}),
                Hjsx$ResX.Elements.jsx("body", {
                      children: props.children
                    })
              ]
            });
}

var Html = {
  make: TestUtils$Html
};

async function getResponse(getContent, onBeforeSendResponse, urlOpt) {
  var url = urlOpt !== undefined ? urlOpt : "/";
  var match = getPort();
  var port = match[0];
  var server = Bun.serve({
        development: true,
        port: port,
        fetch: (async function (request, _server) {
            return await Handlers$ResX.handleRequest(handler, {
                        request: request,
                        render: (async function (renderConfig) {
                            return getContent(renderConfig);
                          }),
                        setupHeaders: (function () {
                            return new Headers([[
                                          "Content-Type",
                                          "text/html"
                                        ]]);
                          }),
                        onBeforeSendResponse: onBeforeSendResponse
                      });
          })
      });
  var res;
  var exit = 0;
  var res$1;
  try {
    res$1 = await fetch("http://localhost:" + port.toString() + url);
    exit = 1;
  }
  catch (raw_exn){
    var exn = Caml_js_exceptions.internalToOCamlException(raw_exn);
    if (exn.RE_EXN_ID === Js_exn.$$Error) {
      res = {
        TAG: "Error",
        _0: "Failed to fetch."
      };
    } else {
      throw exn;
    }
  }
  if (exit === 1) {
    res = {
      TAG: "Ok",
      _0: res$1
    };
  }
  server.stop(true);
  match[1]();
  if (res.TAG === "Ok") {
    return res._0;
  } else {
    return RescriptCore.panic(res._0);
  }
}

async function getContentInBody(getContent) {
  var content = await getResponse(getContent, undefined, undefined);
  return await content.text();
}

var portsBase = 40000;

exports.Handler = Handler;
exports.currentPortsUsed = currentPortsUsed;
exports.portsBase = portsBase;
exports.getPort = getPort;
exports.Html = Html;
exports.getResponse = getResponse;
exports.getContentInBody = getContentInBody;
/* handler Not a pure module */
