import * as H from "rescript-x/H";
import * as Htmx from "rescript-x/Htmx";
import { Actions } from "rescript-x/Client";

export function Home({ helloUrl, timeUrl }: { helloUrl: string; timeUrl: string }) {
  const swap = Htmx.Swap.make("innerHTML", "Transition");
  const actions = Actions.make([
    { kind: "ToggleClass", target: { kind: "This" }, className: "mt-2" },
  ]);

  return (
    <div class="box">
      <h1>ResX + TSX Demo</h1>
      <p>Rendered at: {new Date().toISOString()}</p>

      <div class="mt-2">
        <button class="btn" hx-get={helloUrl} hx-swap={swap} resx-onclick={actions}>
          HTMX: Say Hello
        </button>
      </div>

      <div class="mt-2">
        <button class="btn" hx-get={timeUrl} hx-swap={swap}>
          HTMX: Get Time
        </button>
      </div>

      <div id="htmx-target" class="mt-2"></div>
    </div>
  );
}
