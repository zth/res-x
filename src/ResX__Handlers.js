// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var H = require("./H.js");
var Core__List = require("@rescript/core/src/Core__List.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Core__Array = require("@rescript/core/src/Core__Array.js");
var Core__Option = require("@rescript/core/src/Core__Option.js");
var Nodeasync_hooks = require("node:async_hooks");
var ResX__RequestController = require("./ResX__RequestController.js");

function make(requestToContext) {
  return {
          handlers: [],
          requestToContext: requestToContext,
          asyncLocalStorage: new Nodeasync_hooks.AsyncLocalStorage()
        };
}

function useContext(t) {
  return t.asyncLocalStorage.getStore();
}

function defaultRenderTitle(segments) {
  return segments.join(" | ");
}

async function renderWithDocType(el, requestController, renderTitleOpt) {
  var renderTitle = renderTitleOpt !== undefined ? renderTitleOpt : defaultRenderTitle;
  var match = await Promise.all([
        H.renderToString(el),
        ResX__RequestController.getAppendedHeadContent(requestController)
      ]);
  var appendToHead = match[1];
  var content = match[0];
  var match$1 = ResX__RequestController.getTitleSegments(requestController);
  var appendToHead$1;
  if (match$1.length !== 0) {
    if (appendToHead !== undefined) {
      var titleElement = "<title>" + renderTitle(match$1) + "</title>";
      appendToHead$1 = appendToHead + titleElement;
    } else {
      appendToHead$1 = "<title>" + renderTitle(match$1) + "</title>";
    }
  } else {
    appendToHead$1 = appendToHead;
  }
  var content$1 = appendToHead$1 !== undefined ? content.replace("</head>", appendToHead$1 + "</head>") : content;
  return ResX__RequestController.getDocHeader(requestController) + content$1;
}

var defaultHeaders = [[
    "Content-Type",
    "text/html"
  ]];

async function handleRequest(t, config) {
  var render = config.render;
  var request = config.request;
  var stream = Core__Option.getWithDefault(config.experimental_stream, false);
  var url = new URL(request.url);
  var pathname = url.pathname;
  var targetHandler = Core__Array.findMap(t.handlers, (function (param) {
          if (param[0] === request.method && param[1] === pathname) {
            return param[2];
          }
          
        }));
  var ctx = await t.requestToContext(request);
  var requestController = ResX__RequestController.make();
  var setupHeaders = config.setupHeaders;
  var headers = setupHeaders !== undefined ? setupHeaders() : new Headers(defaultHeaders);
  var renderConfig_path = Core__List.fromArray(pathname.split("/").filter(function (s) {
            return s.trim() !== "";
          }));
  var renderConfig = {
    request: request,
    headers: headers,
    context: ctx,
    path: renderConfig_path,
    url: url,
    requestController: requestController
  };
  return await t.asyncLocalStorage.run(renderConfig, (async function (_token) {
                var content = targetHandler !== undefined ? await targetHandler({
                        request: request,
                        context: ctx,
                        headers: headers,
                        requestController: requestController
                      }) : await render(renderConfig);
                if (stream) {
                  var match = new TransformStream({
                        transform: (function (chunk, controller) {
                            controller.enqueue(chunk);
                          })
                      });
                  var writer = match.writable.getWriter();
                  var textEncoder = new TextEncoder();
                  H.renderToStream(content, (function (chunk) {
                            var encoded = textEncoder.encode(chunk);
                            writer.write(encoded);
                          })).then(function () {
                        writer.close();
                      });
                  return new Response(match.readable, {
                              status: 200,
                              headers: [[
                                  "Content-Type",
                                  "text/html"
                                ]]
                            });
                }
                var content$1 = await renderWithDocType(content, requestController, config.renderTitle);
                var match$1 = ResX__RequestController.getCurrentRedirect(requestController);
                var match$2 = ResX__RequestController.getCurrentStatus(requestController);
                if (match$1 !== undefined) {
                  return Response.redirect(match$1[0], Caml_option.option_get(match$1[1]));
                } else {
                  return new Response(content$1, {
                              status: match$2,
                              headers: Caml_option.some(headers)
                            });
                }
              }));
}

function get(t, path, handler) {
  t.handlers.push([
        "GET",
        path,
        handler
      ]);
  return path;
}

function post(t, path, handler) {
  t.handlers.push([
        "POST",
        path,
        handler
      ]);
  return path;
}

function put(t, path, handler) {
  t.handlers.push([
        "PUT",
        path,
        handler
      ]);
  return path;
}

function $$delete(t, path, handler) {
  t.handlers.push([
        "DELETE",
        path,
        handler
      ]);
  return path;
}

function patch(t, path, handler) {
  t.handlers.push([
        "PATCH",
        path,
        handler
      ]);
  return path;
}

function getHandlers(t) {
  return t.handlers;
}

var Internal = {
  getHandlers: getHandlers
};

exports.make = make;
exports.get = get;
exports.post = post;
exports.put = put;
exports.$$delete = $$delete;
exports.patch = patch;
exports.useContext = useContext;
exports.handleRequest = handleRequest;
exports.Internal = Internal;
/* H Not a pure module */