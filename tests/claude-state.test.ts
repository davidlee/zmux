// Behaviour of the Claude Code state hooks: each case runs the command that
// settings.json registers for an event, as installed under a scratch HOME, against
// a fake `zmx` that records its argv. Nothing here runs Claude Code or zmx.
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdirSync } from "node:fs";
import { join } from "node:path";
import { afterEach, beforeEach, test } from "node:test";
import { harnessDir, registered, scratchHome } from "./hook-fixture.ts";

const hooks = registered(join(harnessDir("claude"), "settings.json"));

let scratch: ReturnType<typeof scratchHome>;

function fire(event: string, { input = {}, env = {}, cwd = scratch.home }: { input?: object; env?: object; cwd?: string } = {}) {
  const [{ hooks: [{ command }] }] = hooks[event];
  return spawnSync("/bin/sh", ["-c", command], {
    cwd,
    encoding: "utf8",
    input: JSON.stringify({ hook_event_name: event, ...input }),
    env: {
      HOME: scratch.home,
      PATH: `${scratch.bin}:${process.env.PATH}`,
      CLAUDE_CODE_ENTRYPOINT: "cli",
      ZMX_SESSION: "docs.1",
      ...env,
    },
  });
}

const title = (result: { stdout: string }) => {
  const sequence: string = JSON.parse(result.stdout).terminalSequence;
  assert.ok(sequence.startsWith("\x1b]0;") && sequence.endsWith("\x07"), "an OSC 0 title");
  return sequence.slice(4, -1);
};

beforeEach(() => {
  scratch = scratchHome("claude", ".claude");
});

afterEach(() => scratch.dispose());

test("a submitted prompt is working, in the session around it", () => {
  fire("UserPromptSubmit");
  assert.deepEqual(scratch.writes(), ["set . state=working"]);
});

for (const event of ["Stop", "StopFailure"]) {
  test(`a turn that ends in ${event} is blocked`, () => {
    fire(event);
    assert.deepEqual(scratch.writes(), ["set . state=blocked"]);
  });
}

test("a permission dialog is blocked", () => {
  fire("PermissionRequest");
  assert.deepEqual(scratch.writes(), ["set . state=blocked"]);
});

for (const event of ["PostToolUse", "PostToolUseFailure"]) {
  test(`${event} replaces a dialog's blocked with working`, () => {
    fire(event);
    assert.deepEqual(scratch.writes(), ["set . state=working"]);
  });

  test(`a subagent's ${event} leaves the state alone, as it can outlast the turn`, () => {
    const result = fire(event, { input: { agent_id: "a1" } });
    assert.deepEqual(scratch.writes(), []);
    assert.equal(result.stdout, "");
  });
}

test("a -p delegate never writes, though it inherits ZMX_SESSION", () => {
  const result = fire("Stop", { env: { CLAUDE_CODE_ENTRYPOINT: "sdk-cli" } });
  assert.deepEqual(scratch.writes(), []);
  assert.equal(result.stdout, "");
});

test("outside a session it does nothing, and succeeds", () => {
  const { status, stdout } = fire("Stop", { env: { ZMX_SESSION: "" } });
  assert.equal(status, 0);
  assert.equal(stdout, "");
  assert.deepEqual(scratch.writes(), []);
});

test("in a jail, with no ZMX_SESSION, it writes through zmx-state", () => {
  scratch.relayed("id=1 project=docs state=blocked");
  assert.equal(title(fire("Stop", { env: { ZMX_SESSION: "" } })), "docs.1 | ~ | 🔔");
  assert.deepEqual(scratch.calls(), ["zmx-state blocked"]);
});

test("in a jail, a session with no project leaves its name out of the title", () => {
  scratch.relayed("state=blocked");
  assert.equal(title(fire("Stop", { env: { ZMX_SESSION: "" } })), "~ | 🔔");
});

test("a -p delegate never writes from a jail either", () => {
  scratch.relayed("id=1 project=docs");
  fire("Stop", { env: { ZMX_SESSION: "", CLAUDE_CODE_ENTRYPOINT: "sdk-cli" } });
  assert.deepEqual(scratch.calls(), []);
});

test("a failing zmx never fails Claude Code", () => {
  scratch.fakeZmx("echo refused >&2\nexit 1");
  const { status, stdout, stderr } = fire("Stop");
  assert.equal(status, 0);
  assert.equal(stdout, "");
  assert.equal(stderr, "");
});

test("labels that can't be read still leave a title, since the state was written", () => {
  scratch.fakeZmx('[ "$1" = set ]');
  assert.equal(title(fire("Stop")), "docs.1 | ~ | 🔔");
  assert.deepEqual(scratch.writes(), ["set . state=blocked"]);
});

test("the title names the session, the directory and the state, as zmx-title does", () => {
  assert.equal(title(fire("Stop")), "docs.1 | ~ | 🔔");
  assert.equal(title(fire("UserPromptSubmit")), "docs.1 | ~ | ◐");
});

test("the title shows a role when there is one", () => {
  scratch.labels("id=1 project=docs role=test-runner state=blocked");
  assert.equal(title(fire("Stop")), "docs.1 | test-runner | ~ | 🔔");
});

test("the title falls back to the session's name when it has no labels", () => {
  scratch.labels("");
  assert.equal(title(fire("Stop", { env: { ZMX_SESSION: "scratch" } })), "scratch | ~ | 🔔");
});

test("the title keeps a directory outside home whole", () => {
  assert.equal(title(fire("Stop", { cwd: "/" })), "docs.1 | / | 🔔");
});

test("a directory holding control characters still yields a title", () => {
  const cwd = join(scratch.home, "a\nb\x07");
  mkdirSync(cwd);
  assert.equal(title(fire("Stop", { cwd })), "docs.1 | ~/ab | 🔔");
});

test("a directory that needs escaping still yields a title", () => {
  const cwd = join(scratch.home, 'a"b\\c');
  mkdirSync(cwd);
  assert.equal(title(fire("Stop", { cwd })), 'docs.1 | ~/a"b\\c | 🔔');
});
