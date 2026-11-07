// A scratch HOME for testing a harness's state hook: the script installed as its
// fragment expects, and a fake `zmx` that records its argv. Nothing here runs a
// harness or zmx.
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

export const harnessDir = (name: string) => resolve(import.meta.dirname, "../harness", name);

// The hook commands a fragment registers for an event, which read the same in
// Claude Code's settings.json and Codex's hooks.json.
export const registered = (fragment: string) => JSON.parse(readFileSync(fragment, "utf8")).hooks;

export function scratchHome(harness: string, configDir: string) {
  const home = mkdtempSync(join(tmpdir(), `zmx-${harness}-`));
  const bin = join(home, "bin");
  mkdirSync(bin);
  mkdirSync(join(home, configDir, "hooks"), { recursive: true });
  symlinkSync(join(harnessDir(harness), "zmx-state.sh"), join(home, configDir, "hooks/zmx-state.sh"));

  const fakeZmx = (body: string) => {
    const path = join(bin, "zmx");
    writeFileSync(path, `#!/bin/sh\necho "$*" >> "${join(home, "calls")}"\n${body}\n`);
    chmodSync(path, 0o755);
  };
  const labels = (line: string) => fakeZmx(`[ "$1" = get ] && echo '${line}'\nexit 0`);
  const writes = () => {
    const log = join(home, "calls");
    const calls = existsSync(log) ? readFileSync(log, "utf8").trim().split("\n") : [];
    return calls.filter((call) => call.startsWith("set "));
  };

  labels("id=1 project=docs");
  return { home, bin, fakeZmx, labels, writes, dispose: () => rmSync(home, { recursive: true }) };
}
