// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Demo = require("./Demo.js");
var StaticExporter = require("res-x/src/StaticExporter.js");

var urls = [
  "/",
  "/start",
  "/user/1"
];

StaticExporter.run(Demo.server, urls);

exports.urls = urls;
/*  Not a pure module */