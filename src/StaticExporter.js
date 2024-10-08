// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Nodefs = require("node:fs");

function debug(s) {
  console.log("[debug]", s);
}

function log(s) {
  console.log("[info]", s);
}

async function run(server, urls) {
  var serverUrl = "http://" + server.hostname + ":" + server.port.toString();
  var s = "Exporting " + urls.length.toString() + " URLs.";
  console.log("[info]", s);
  await Promise.all(urls.map(async function (url) {
            console.log("[info]", "[export] " + url + " - Exporting...");
            var res = await fetch(serverUrl + url);
            var otherStatus = res.status;
            if (otherStatus !== 200) {
              console.error(url + " gave status " + otherStatus.toString());
              return ;
            }
            var structure = url.split("/").filter(function (p) {
                    return p !== "";
                  }).toReversed();
            var f = structure[0];
            var match = f !== undefined && f !== "" ? [
                1,
                f + ".html"
              ] : [
                0,
                "index.html"
              ];
            structure.push("dist");
            var dirStructure = structure.slice(match[0]).toReversed();
            if (dirStructure.length !== 0) {
              await Nodefs.promises.mkdir(dirStructure.join("/"), {
                    recursive: true
                  });
            }
            dirStructure.push(match[1]);
            var filePath = dirStructure.join("/");
            await Bun.write(Bun.file(dirStructure.join("/")), res);
            console.log("[info]", "[export] " + url + " - Wrote " + filePath + ".");
          }));
  console.log("[info]", "Done.");
  server.stop(true);
  return process.exit(0);
}

var debugging = true;

exports.debugging = debugging;
exports.debug = debug;
exports.log = log;
exports.run = run;
/* node:fs Not a pure module */
