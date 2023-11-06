// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var HtmxHandler = require("./HtmxHandler.js");
var ResX__ReactDOM = require("res-x/src/ResX__ReactDOM.js");
var ResX__RequestController = require("res-x/src/ResX__RequestController.js");

function FourOhFour(props) {
  var __setGenericTitle = props.setGenericTitle;
  var setGenericTitle = __setGenericTitle !== undefined ? __setGenericTitle : false;
  var context = HtmxHandler.useContext();
  ResX__RequestController.setStatus(context.requestController, 404);
  if (setGenericTitle) {
    ResX__RequestController.setFullTitle(context.requestController, "Not Found");
  }
  return ResX__ReactDOM.jsx("div", {
              children: "404"
            });
}

var make = FourOhFour;

exports.make = make;
/* HtmxHandler Not a pure module */
