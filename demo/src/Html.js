// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var Dev = require("rescript-x/src/Dev.js");
var ResXAssets = require("./__generated__/ResXAssets.js");
var ResX__React = require("rescript-x/src/ResX__React.js");
var ResX__ReactDOM = require("rescript-x/src/ResX__ReactDOM.js");

function Html(props) {
  return ResX__ReactDOM.jsxs("html", {
              children: [
                ResX__ReactDOM.jsx("head", {
                      children: ResX__ReactDOM.jsx("link", {
                            href: ResXAssets.assets.styles_css,
                            rel: "stylesheet",
                            type: "text/css"
                          })
                    }),
                ResX__ReactDOM.jsxs("body", {
                      children: [
                        props.children,
                        ResX__React.jsx(Dev.make, {}),
                        ResX__ReactDOM.jsx("script", {
                              src: "https://unpkg.com/htmx.org@1.9.5"
                            }),
                        ResX__ReactDOM.jsx("script", {
                              async: true,
                              src: ResXAssets.assets.resXClient_js
                            })
                      ],
                      className: "bg-orange-200 p-10",
                      "hx-boost": true
                    })
              ]
            });
}

var make = Html;

exports.make = make;
/* Dev Not a pure module */
