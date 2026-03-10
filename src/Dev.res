@@jsxConfig({module_: "Hjsx"})

let getScript = () =>
  `(() => {
let hasConnectedOnce = false;
let reconnectTimeout = null;
let overlay = null;

function getDevSocketUrl() {
  let protocol = window.location.protocol === "https:" ? "wss" : "ws";
  return protocol + "://" + window.location.host + "/_resx_dev";
}

function getOverlay() {
  if (overlay !== null) {
    return overlay;
  }

  let existingOverlay = document.getElementById("__resx-dev-overlay");
  if (existingOverlay != null) {
    overlay = existingOverlay;
    return existingOverlay;
  }

  let nextOverlay = document.createElement("div");
  nextOverlay.id = "__resx-dev-overlay";
  nextOverlay.textContent = "Server restarting...";
  nextOverlay.style.position = "fixed";
  nextOverlay.style.right = "16px";
  nextOverlay.style.bottom = "16px";
  nextOverlay.style.zIndex = "2147483647";
  nextOverlay.style.padding = "8px 12px";
  nextOverlay.style.borderRadius = "999px";
  nextOverlay.style.background = "rgba(15, 23, 42, 0.92)";
  nextOverlay.style.color = "#fff";
  nextOverlay.style.font = "12px/1.2 system-ui, sans-serif";
  nextOverlay.style.boxShadow = "0 8px 24px rgba(0, 0, 0, 0.25)";
  nextOverlay.style.display = "none";
  document.body.appendChild(nextOverlay);
  overlay = nextOverlay;
  return nextOverlay;
}

function showOverlay() {
  if (document.body == null) {
    document.addEventListener("DOMContentLoaded", showOverlay, { once: true })
    return;
  }

  getOverlay().style.display = "block";
}

function hideOverlay() {
  if (overlay !== null) {
    overlay.style.display = "none";
  }
}

function scheduleReconnect() {
  clearTimeout(reconnectTimeout);
  reconnectTimeout = setTimeout(bootSocket, 200);
}

function bootSocket() {
  let socket;

  try {
    socket = new WebSocket(getDevSocketUrl());
  } catch (_error) {
    showOverlay();
    scheduleReconnect();
    return;
  }

  socket.addEventListener("close", _event => {
    showOverlay();
    scheduleReconnect();
  })

  socket.addEventListener("error", _event => {
    if (socket.readyState !== WebSocket.OPEN) {
      socket.close();
    }
  })

  socket.addEventListener("open", _event => {
    hideOverlay();
    if (hasConnectedOnce) {
      window.location.reload();
      return;
    }
    hasConnectedOnce = true;
  })
}

bootSocket()
})()
`

@jsx.component
let make = () => {
  if BunUtils.isDev {
    <script
      dangerouslySetInnerHTML={{
        "__html": getScript(),
      }}
    />
  } else {
    Hjsx.null
  }
}
