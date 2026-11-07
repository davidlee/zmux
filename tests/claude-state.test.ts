// Behaviour of the Claude Code state hooks: each case runs the command that
// settings.json registers for an event, as installed under a scratch HOME, against
// a fake `zmx` that records its argv. Nothing here runs Claude Code or zmx.
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { afterEach, beforeEach, test } from "node:test";

const harness = resolve(import.meta.dirname, "../harness/claude");
const { hooks } = JSON.parse(readFileSync(join(harness, "settings.json"), "utf8"));

let home: string;
const bin = () => join(home, "bin");
const writes = () => {
  const log = join(home, "calls");
  const calls = existsSync(log) ? readFileSync(log, "utf8").trim().split("\n") : [];
  return calls.filter((call) => call.startsWith("set "));
};

function fakeZmx(body: string) {
  const path = join(bin(), "zmx");
  writeFileSync(path, `#!/bin/sh\necho "$*" >> "${join(home, "calls")}"\n${body}\n`);
  chmodSync(path, 0o755);
}

const labels = (line: string) => fakeZmx(`[ "$1" = get ] && echo '${line}'\nexit 0`);

function fire(event: string, { input = {}, env = {}, cwd = home }: { input?: object; env?: object; cwd?: string } = {}) {
  const [{ hooks: [{ command }] }] = hooks[event];
  return spawnSync("/bin/sh", ["-c", command], {
    cwd,
    encoding: "utf8",
    input: JSON.stringify({ hook_event_name: event, ...input }),
    env: {
      HOME: home,
      PATH: `${bin()}:${process.env.PATH}`,
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
  home = mkdtempSync(join(tmpdir(), "zmx-claude-"));
  mkdirSync(bin());
  mkdirSync(join(home, ".claude/hooks"), { recursive: true });
  symlinkSync(join(harness, "zmx-state.sh"), join(home, ".claude/hooks/zmx-state.sh"));
  labels("id=1 project=docs");
});

afterEach(() => rmSync(home, { recursive: true }));

test("a submitted prompt is working, in the session around it", () => {
  fire("UserPromptSubmit");
  assert.deepEqual(writes(), ["set . state=working"]);
});

for (const event of ["Stop", "StopFailure"]) {
  test(`a turn that ends in ${event} is blocked`, () => {
    fire(event);
    assert.deepEqual(writes(), ["set . state=blocked"]);
  });
}

test("a permission dialog is blocked", () => {
  fire("PermissionRequest");
  assert.deepEqual(writes(), ["set . state=blocked"]);
});

for (const event of ["PostToolUse", "PostToolUseFailure"]) {
  test(`${event} replaces a dialog's blocked with working`, () => {
    fire(event);
    assert.deepEqual(writes(), ["set . state=working"]);
  });

  test(`a subagent's ${event} leaves the state alone, as it can outlast the turn`, () => {
    const result = fire(event, { input: { agent_id: "a1" } });
    assert.deepEqual(writes(), []);
    assert.equal(result.stdout, "");
  });
}

test("a -p delegate never writes, though it inherits ZMX_SESSION", () => {
  const result = fire("Stop", { env: { CLAUDE_CODE_ENTRYPOINT: "sdk-cli" } });
  assert.deepEqual(writes(), []);
  assert.equal(result.stdout, "");
});

test("outside a session it does nothing, and succeeds", () => {
  const { status, stdout } = fire("Stop", { env: { ZMX_SESSION: "" } });
  assert.equal(status, 0);
  assert.equal(stdout, "");
  assert.deepEqual(writes(), []);
});

test("a failing zmx never fails Claude Code", () => {
  fakeZmx("exit 1");
  const { status, stdout } = fire("Stop");
  assert.equal(status, 0);
  assert.equal(stdout, "");
});

test("a missing zmx never fails Claude Code", () => {
  rmSync(join(bin(), "zmx"));
  const { status, stderr } = fire("Stop", { env: { PATH: bin() } });
  assert.equal(status, 0);
  assert.equal(stderr, "");
});

test("the title names the session, the directory and the state, as zmx-title does", () => {
  assert.equal(title(fire("Stop")), "docs.1 | ~ | 🔔");
  assert.equal(title(fire("UserPromptSubmit")), "docs.1 | ~ | ◐");
});

test("the title shows a role when there is one", () => {
  labels("id=1 project=docs role=test-runner state=blocked");
  assert.equal(title(fire("Stop")), "docs.1 | test-runner | ~ | 🔔");
});

test("the title falls back to the session's name when it has no labels", () => {
  labels("");
  assert.equal(title(fire("Stop", { env: { ZMX_SESSION: "scratch" } })), "scratch | ~ | 🔔");
});

test("the title keeps a directory outside home whole", () => {
  assert.equal(title(fire("Stop", { cwd: "/" })), "docs.1 | / | 🔔");
});

test("a directory that needs escaping still yields a title", () => {
  const cwd = join(home, 'a"b\\c');
  mkdirSync(cwd);
  assert.equal(title(fire("Stop", { cwd })), 'docs.1 | ~/a"b\\c | 🔔');
});
