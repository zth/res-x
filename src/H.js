// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Caml_option = require("rescript/lib/js/caml_option.js");
var HyperonsJs = require("./vendor/hyperons.js");

function renderToString(prim) {
  return HyperonsJs.render(prim);
}

function renderSyncToString(prim) {
  return HyperonsJs.renderSync(prim);
}

function renderToStream(prim0, prim1) {
  return HyperonsJs.render(prim0, prim1 !== undefined ? Caml_option.valFromOption(prim1) : undefined);
}

function createContext(prim) {
  return HyperonsJs.createContext(prim);
}

function useContext(prim) {
  return HyperonsJs.useContext(prim);
}

var Context = {
  createContext: createContext,
  useContext: useContext
};

exports.renderToString = renderToString;
exports.renderSyncToString = renderSyncToString;
exports.renderToStream = renderToStream;
exports.Context = Context;
/* ./vendor/hyperons.js Not a pure module */
