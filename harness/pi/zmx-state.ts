// Advertises an interactive pi waiting at its prompt as `state=blocked` on the zmx
// session around it, and `state=working` once it resumes (DEC-009).
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const WRITE_TIMEOUT_MS = 5000;

export default function (pi: ExtensionAPI) {
  let current: string | undefined;
  let writes: Promise<unknown> = Promise.resolve();

  // Not awaited, so a hung zmx-state can't stall a run; chained, so a slow write can't
  // land after a later one.
  const advertise = (state: string, ctx: ExtensionContext) => {
    // Delegates can reach the session too, and only a terminal has a human behind it.
    if (ctx.mode !== "tui" || state === current) return;
    current = state;
    writes = writes
      .then(() => pi.exec("zmx-state", [state], { timeout: WRITE_TIMEOUT_MS }))
      .catch(() => {});
  };

  pi.on("agent_start", (_event, ctx) => advertise("working", ctx));
  // Not agent_end: retries and queued messages can follow it.
  pi.on("agent_settled", (_event, ctx) => advertise("blocked", ctx));
}
