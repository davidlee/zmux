// Behaviour of the host's `zmx-state`, against a fake `zmx`. The jail's has the same
// contract, and lives with the relay in ~/flakes (flakes:IMP-070).
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { join } from "node:path";
import { afterEach, beforeEach, test } from "node:test";
import { scratchZmx } from "./hook-fixture.ts";

let scratch: ReturnType<typeof scratchZmx>;

const run = (args: string[], session = "docs.1") =>
  spawnSync("zmx-state", args, {
    encoding: "utf8",
    input: "the hook's own input",
    env: { PATH: `${scratch.bin}:${process.env.PATH}`, ZMX_SESSION: session },
  });

beforeEach(() => {
  scratch = scratchZmx();
});

afterEach(() => scratch.dispose());

for (const value of ["working", "blocked"]) {
  test(`${value} is written on the session around it, and its labels are printed`, () => {
    const { status, stdout } = run([value]);
    assert.equal(status, 0);
    assert.equal(stdout, "id=1 project=docs");
    assert.deepEqual(scratch.calls(), [`set . state=${value}`, "get ."]);
  });
}

test("outside a session it does nothing, and succeeds", () => {
  const { status, stdout } = run(["blocked"], "");
  assert.equal(status, 0);
  assert.equal(stdout, "");
  assert.deepEqual(scratch.calls(), []);
});

for (const args of [["done"], ["failed"], ["blocked; rm"], []]) {
  test(`a harness can't write ${JSON.stringify(args)}`, () => {
    const { status, stdout } = run(args);
    assert.equal(status, 0);
    assert.equal(stdout, "");
    assert.deepEqual(scratch.calls(), []);
  });
}

test("a refused write prints nothing and succeeds", () => {
  scratch.fakeZmx("echo refused >&2\nexit 1");
  const { status, stdout, stderr } = run(["blocked"]);
  assert.equal(status, 0);
  assert.equal(stdout, "");
  assert.equal(stderr, "");
});

test("labels that can't be read leave the one just written", () => {
  scratch.fakeZmx('[ "$1" = set ]');
  const { status, stdout } = run(["blocked"]);
  assert.equal(status, 0);
  assert.equal(stdout, "state=blocked");
});

test("zmx gets none of the caller's stdin", () => {
  const seen = join(scratch.home, "stdin");
  scratch.fakeZmx(`cat >> "${seen}"`);
  run(["blocked"]);
  assert.equal(spawnSync("cat", [seen], { encoding: "utf8" }).stdout, "");
});
