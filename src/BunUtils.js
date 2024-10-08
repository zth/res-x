// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var FastGlob = require("fast-glob");
var Caml_option = require("rescript/lib/js/caml_option.js");

var isDev = process.env.NODE_ENV !== "production";

async function loadStaticFiles(root) {
  return await FastGlob.glob(isDev ? [
                "public/**/*",
                "assets/**/*"
              ] : ["dist/**/*"], {
              dot: true,
              cwd: root !== undefined ? root : process.cwd()
            });
}

var staticFiles = {
  contents: undefined
};

async function serveStaticFile(request) {
  var s = staticFiles.contents;
  var staticFiles$1;
  if (s !== undefined) {
    staticFiles$1 = Caml_option.valFromOption(s);
  } else {
    var files = await loadStaticFiles(undefined);
    var files$1 = new Map(files.map(function (f) {
              return [
                      isDev ? (
                          f.startsWith("public/") ? f.slice(7) : f
                        ) : (
                          f.startsWith("dist/") ? f.slice(5) : f
                        ),
                      f
                    ];
            }));
    staticFiles.contents = Caml_option.some(files$1);
    staticFiles$1 = files$1;
  }
  var url = new URL(request.url);
  var pathname = url.pathname;
  var path = pathname.split("/").filter(function (p) {
        return p !== "";
      });
  var joined = path.join("/");
  var fileLoc = staticFiles$1.get(joined);
  if (fileLoc === undefined) {
    return ;
  }
  var bunFile = Bun.file("./" + fileLoc);
  var match = bunFile.size;
  return Caml_option.some(match !== 0 ? new Response(bunFile) : new Response("", {
                    status: 404
                  }));
}

function runDevServer(port) {
  Bun.serve({
        development: true,
        port: port + 1 | 0,
        fetch: (async function (request, server) {
            if (server.upgrade(request)) {
              return undefined;
            } else {
              return new Response("", {
                          status: 404
                        });
            }
          }),
        websocket: {
          open: (function (_v) {
              
            })
        }
      });
}

function copy(search) {
  return new URLSearchParams(Object.fromEntries(search.entries()));
}

var $$URLSearchParams$1 = {
  copy: copy
};

exports.serveStaticFile = serveStaticFile;
exports.runDevServer = runDevServer;
exports.isDev = isDev;
exports.$$URLSearchParams = $$URLSearchParams$1;
/* isDev Not a pure module */
