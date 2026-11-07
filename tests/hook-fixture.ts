// A scratch HOME for testing a harness's state hook: the script installed as its
// fragment expects, the real `zmx-state`, and a fake `zmx` that records its argv.
// Nothing here runs a harness or zmx.
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

export const harnessDir = (name: string) => resolve(import.meta.dirname, "../harness", name);

// The hook commands a fragment registers for an event, which read the same in
// Claude Code's settings.json and Codex's hooks.json.
export const registered = (fragment: string) => JSON.parse(readFileSync(fragment, "utf8")).hooks;

// `zmx-state` on PATH in front of a fake `zmx`.
export function scratchZmx() {
  const home = mkdtempSync(join(tmpdir(), "zmx-state-"));
  const bin = join(home, "bin");
  const stateCommand = join(bin, "zmx-state");
  mkdirSync(bin);
  symlinkSync(resolve(import.meta.dirname, "../pkgs/zmx-state/zmx-state.sh"), stateCommand);

  const log = join(home, "calls");
  const script = (path: string, body: string) => {
    rmSync(path, { force: true });
    writeFileSync(path, `#!/bin/sh\n${body}\n`);
    chmodSync(path, 0o755);
  };
  const fakeZmx = (body: string) => script(join(bin, "zmx"), `echo "$*" >> "${log}"\n${body}`);
  const labels = (line: string) => fakeZmx(`[ "$1" = get ] && echo '${line}'\nexit 0`);
  // As a jail has it: no `zmx` of any use, and a relay's reply, without a newline.
  const relayed = (reply: string) => script(stateCommand, `echo "zmx-state $*" >> "${log}"\nprintf '%s' '${reply}'`);
  const calls = () => (existsSync(log) ? readFileSync(log, "utf8").trim().split("\n") : []);
  const writes = () => calls().filter((call) => call.startsWith("set "));

  labels("id=1 project=docs");
  return { home, bin, fakeZmx, labels, relayed, calls, writes, dispose: () => rmSync(home, { recursive: true }) };
}

export function scratchHome(harness: string, configDir: string) {
  const scratch = scratchZmx();
  mkdirSync(join(scratch.home, configDir, "hooks"), { recursive: true });
  symlinkSync(join(harnessDir(harness), "zmx-state.sh"), join(scratch.home, configDir, "hooks/zmx-state.sh"));
  return scratch;
}
