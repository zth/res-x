// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var ResX__ReactDOM = require("res-x/src/ResX__ReactDOM.js");

function wait() {
  return new Promise((function (resolve, _reject) {
                setTimeout((function () {
                        resolve();
                      }), 1000);
              }));
}

async function make(param) {
  await wait();
  return ResX__ReactDOM.jsxs("div", {
              children: [
                "This was deferred.",
                ResX__ReactDOM.jsx("div", {
                      children: param.children
                    })
              ]
            });
}

var DeferredComponent = make;

var make$1 = DeferredComponent;

exports.wait = wait;
exports.make = make$1;
/* ResX__ReactDOM Not a pure module */