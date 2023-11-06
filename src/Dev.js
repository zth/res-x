// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var BunUtils = require("./BunUtils.js");
var ResX__ReactDOM = require("./ResX__ReactDOM.js");

function getScript(port) {
  return "(() => {\nlet hasMadeInitialConnection = false;\nlet timeout;\nlet socket = null;\nlet reconnectInterval;\nlet debugging = true;\n\nlet debug = (...msg) => {\n  if (debugging) {\n    console.log(...msg)\n  }\n}\n\nfunction reload() {\n  clearTimeout(timeout)\n  timeout = setTimeout(() => {\n    window.location.reload()\n  }, 200)\n}\n\nfunction connect() {\n  clearInterval(reconnectInterval)\n  reconnectInterval = setInterval(() => {\n    if (socket == null || socket.readyState === 2 || socket.readyState === 3) {\n      bootSocket()\n    } else if (socket != null && (socket.readyState === 0 || socket.readyState === 1)) {\n      clearInterval(reconnectInterval)\n    }\n  }, 200)\n}\n\nfunction updateContent() {\n  fetch(document.location.href).then(async res => {\n    let text = await res.text()\n    try {\n      let domParser = new DOMParser()\n      let fromDom = document.documentElement\n      let toDom = domParser.parseFromString(text, \"text/html\").querySelector(\"html\")\n      morphdom(fromDom, toDom, {\n        onBeforeElUpdated: function(fromEl, toEl) {\n          if (fromEl.isEqualNode(toEl)) {\n            return false;\n          }\n          \n          if (fromEl.tagName === 'INPUT') {\n            if (fromEl.type === 'checkbox' || fromEl.type === 'radio') {\n              toEl.checked = fromEl.checked;\n            } else {\n              toEl.value = fromEl.value;\n            }\n          } else if (fromEl.tagName === 'TEXTAREA') {\n            toEl.value = fromEl.value;\n          }\n\n          if (fromEl.tagName === 'SELECT') {\n            toEl.selectedIndex = fromEl.selectedIndex;\n          }\n\n          return true;\n        }\n      })\n      debug(\"[dev] Content reloaded.\")\n    } catch(e) {\n      console.warn(\"[dev] Error morphing DOM. Doing full reload.\")\n      console.error(e)\n      document.documentElement.innerHTML = text\n\n    }\n  })\n}\n\nfunction bootSocket() {\n  socket = new WebSocket(\"ws://localhost:" + (port + 1 | 0).toString() + "\")\n  socket.addEventListener(\"close\", event => {\n    debug(\"[dev] Server restarting\")\n    if (event.isTrusted) {\n      socket = null\n      connect()\n    }\n  })\n  socket.addEventListener(\"open\", event => {\n    debug(\"[dev] Server connection opened.\")\n    if (hasMadeInitialConnection) {\n      updateContent()\n    }\n    hasMadeInitialConnection = true\n  })\n}\n\nbootSocket()\n})()\n";
}

function Dev(props) {
  var __port = props.port;
  var port = __port !== undefined ? __port : 4444;
  if (BunUtils.isDev) {
    return [
            ResX__ReactDOM.jsx("script", {
                  dangerouslySetInnerHTML: {
                    __html: getScript(port)
                  }
                }),
            ResX__ReactDOM.jsx("script", {
                  src: "https://unpkg.com/morphdom/dist/morphdom-umd.js"
                }),
            ResX__ReactDOM.jsx("script", {
                  src: "http://localhost:9000/@vite/client",
                  type: "module"
                })
          ];
  } else {
    return null;
  }
}

var make = Dev;

exports.getScript = getScript;
exports.make = make;
/* BunUtils Not a pure module */
