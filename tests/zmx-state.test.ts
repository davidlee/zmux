// Behaviour of the pi state extension, driven through a fake of the two pi
// surfaces it touches: events in, `zmx` calls out. Nothing here runs pi or zmx.
import assert from "node:assert/strict";
import { beforeEach, test } from "node:test";
import zmxState from "../harness/pi/zmx-state.ts";

type Exec = (command: string, args: string[]) => Promise<unknown>;

function fakePi(exec: Exec = async () => ({ code: 0 })) {
  const handlers = new Map<string, (event: unknown, ctx: unknown) => unknown>();
  const calls: string[][] = [];
  const pi = {
    on: (name: string, handler: (event: unknown, ctx: unknown) => unknown) => handlers.set(name, handler),
    exec: (command: string, args: string[]) => {
      calls.push([command, ...args]);
      return exec(command, args);
    },
  };
  const emit = (name: string, mode = "tui") => handlers.get(name)?.({}, { mode });
  return { pi, calls, handlers, emit };
}

const flush = () => new Promise((resolve) => setImmediate(resolve));
const states = (calls: string[][]) => calls.map((call) => call.at(-1));

beforeEach(() => {
  process.env.ZMX_SESSION = "docs.1";
});

test("does nothing when no zmx session is around it", async () => {
  delete process.env.ZMX_SESSION;
  const { pi, handlers } = fakePi();
  zmxState(pi as never);
  assert.equal(handlers.size, 0);
});

test("a settled pi is blocked, in its own session", async () => {
  const { pi, calls, emit } = fakePi();
  zmxState(pi as never);
  emit("agent_settled");
  await flush();
  assert.deepEqual(calls, [["zmx", "set", "docs.1", "state=blocked"]]);
});

test("resuming replaces blocked with working", async () => {
  const { pi, calls, emit } = fakePi();
  zmxState(pi as never);
  emit("agent_settled");
  emit("agent_start");
  await flush();
  assert.deepEqual(states(calls), ["state=blocked", "state=working"]);
});

test("a first run replaces a blocked left by an earlier pi", async () => {
  const { pi, calls, emit } = fakePi();
  zmxState(pi as never);
  emit("agent_start");
  await flush();
  assert.deepEqual(states(calls), ["state=working"]);
});

test("a retry within one run writes once", async () => {
  const { pi, calls, emit } = fakePi();
  zmxState(pi as never);
  emit("agent_start");
  emit("agent_start");
  await flush();
  assert.equal(calls.length, 1);
});

for (const mode of ["rpc", "json", "print"]) {
  test(`a ${mode} pi leaves the session alone`, async () => {
    const { pi, calls, emit } = fakePi();
    zmxState(pi as never);
    emit("agent_start", mode);
    emit("agent_settled", mode);
    await flush();
    assert.deepEqual(calls, []);
  });
}

test("writes land in order, one at a time", async () => {
  const releases: (() => void)[] = [];
  const { pi, calls, emit } = fakePi(() => new Promise((resolve) => releases.push(() => resolve({ code: 0 }))));
  zmxState(pi as never);
  emit("agent_settled");
  emit("agent_start");
  await flush();
  assert.deepEqual(states(calls), ["state=blocked"]);
  releases[0]();
  await flush();
  assert.deepEqual(states(calls), ["state=blocked", "state=working"]);
});

test("a hung zmx does not hold the handler", async () => {
  const { pi, emit } = fakePi(() => new Promise(() => {}));
  zmxState(pi as never);
  assert.equal(emit("agent_settled"), undefined);
});

test("a failed zmx call stays silent and later writes still run", async () => {
  const { pi, calls, emit } = fakePi(() => Promise.reject(new Error("no zmx")));
  zmxState(pi as never);
  emit("agent_settled");
  emit("agent_start");
  await flush();
  assert.deepEqual(states(calls), ["state=blocked", "state=working"]);
});
