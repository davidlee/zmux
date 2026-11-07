// Behaviour of the Codex state hooks: each case runs the command that hooks.json
// registers for an event, as installed under a scratch HOME, against a fake `zmx`.
// As under Codex, the hook's own stdout is captured, and its parent holds the
// terminal, or a pipe for a delegate. Nothing here runs Codex or zmx.
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { afterEach, beforeEach, test } from "node:test";
import { harnessDir, registered, scratchHome } from "./hook-fixture.ts";

const hooks = registered(join(harnessDir("codex"), "hooks.json"));

let scratch: ReturnType<typeof scratchHome>;

// Stands in for Codex: holds the terminal, and captures the hook's stdout.
const codex = `
  const { spawnSync } = require("node:child_process");
  const { HOOK, HOOK_INPUT, HOOK_STDOUT } = process.env;
  // As Codex's login shell can: it outlives a plain command, unless that execs.
  const { status, stdout } = spawnSync("/bin/sh", ["-c", "trap : EXIT; " + HOOK], { input: HOOK_INPUT, encoding: "utf8" });
  require("node:fs").writeFileSync(HOOK_STDOUT, stdout);
  console.log("status=" + status);
`;

type Fire = { input?: object; env?: object; terminal?: boolean; cwd?: string };

function fire(event: string, { input = {}, env = {}, terminal = true, cwd = scratch.home }: Fire = {}) {
  const [{ hooks: [{ command }] }] = hooks[event];
  const parent = join(scratch.home, "codex.cjs");
  const hookStdout = join(scratch.home, "stdout");
  writeFileSync(parent, codex);
  const argv = `${process.execPath} ${parent}`;
  const [file, args] = terminal ? ["script", ["-qec", argv, "/dev/null"]] : [process.execPath, [parent]];
  const result = spawnSync(file, args, {
    cwd,
    encoding: "utf8",
    env: {
      HOME: scratch.home,
      PATH: `${scratch.bin}:${process.env.PATH}`,
      SHELL: "/bin/sh",
      ZMX_SESSION: "docs.1",
      HOOK: command,
      HOOK_INPUT: JSON.stringify({ hook_event_name: event, ...input }),
      HOOK_STDOUT: hookStdout,
      ...env,
    },
  });
  return { screen: result.stdout, hookStdout: readFileSync(hookStdout, "utf8") };
}

const title = ({ screen }: { screen: string }) => screen.match(/\x1b\]0;(.*?)\x07/)?.[1];

beforeEach(() => {
  scratch = scratchHome("codex", ".codex");
});

afterEach(() => scratch.dispose());

test("a submitted prompt is working, in the session around it", () => {
  fire("UserPromptSubmit");
  assert.deepEqual(scratch.writes(), ["set . state=working"]);
});

for (const event of ["Stop", "Interrupt"]) {
  test(`a turn that ends in ${event} is blocked`, () => {
    fire(event);
    assert.deepEqual(scratch.writes(), ["set . state=blocked"]);
  });
}

test("PostToolUse is working, since a tool only runs in a turn", () => {
  fire("PostToolUse");
  assert.deepEqual(scratch.writes(), ["set . state=working"]);
});

test("a subagent's PostToolUse leaves the state alone, as it can outlast the turn", () => {
  fire("PostToolUse", { input: { agent_id: "a1" } });
  assert.deepEqual(scratch.writes(), []);
});

test("PermissionRequest is not registered: under auto_review no human is asked", () => {
  assert.equal(hooks.PermissionRequest, undefined);
});

test("every hook's timeout fits Interrupt's limit of three seconds", () => {
  for (const [{ hooks: [{ timeout }] }] of Object.values<any>(hooks)) assert.ok(timeout <= 3);
});

test("a delegate on a pipe never writes, though it inherits ZMX_SESSION", () => {
  const { screen } = fire("Stop", { terminal: false });
  assert.deepEqual(scratch.writes(), []);
  assert.match(screen, /status=0/);
});

test("outside a session it does nothing, and succeeds", () => {
  const result = fire("Stop", { env: { ZMX_SESSION: "" } });
  assert.match(result.screen, /status=0/);
  assert.equal(title(result), undefined);
  assert.deepEqual(scratch.writes(), []);
});

test("a failing zmx never fails Codex, and sets no title", () => {
  scratch.fakeZmx("exit 1");
  const result = fire("Stop");
  assert.match(result.screen, /status=0/);
  assert.equal(title(result), undefined);
});

test("the title reaches the terminal, in zmx-title's format", () => {
  assert.equal(title(fire("Stop")), "docs.1 | ~ | 🔔");
  assert.equal(title(fire("UserPromptSubmit")), "docs.1 | ~ | ◐");
});

test("a directory can't end the title and reach the terminal", () => {
  const cwd = join(scratch.home, "a\x07\x1b]2;injected\x07");
  mkdirSync(cwd);
  const result = fire("Stop", { cwd });
  assert.equal(title(result), "docs.1 | ~/a]2;injected | 🔔");
  assert.doesNotMatch(result.screen, /\x1b\]2/);
});

test("the hook prints nothing itself, since Stop refuses plain text", () => {
  assert.equal(fire("Stop").hookStdout, "");
});
