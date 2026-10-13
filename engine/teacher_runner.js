import { createAgentApi } from "./agent_api.js";

const TAU = Math.PI * 2;
const signedAngle = value => ((value + Math.PI) % TAU + TAU) % TAU - Math.PI;
const doomAngle = raw => raw * TAU / 4294967296;

/**
 * Privileged scripted teacher. The policy never receives truth fields: they are
 * retained only for audit while the rendered canvas is the student input.
 */
export async function runTeacherEpisode(Module, canvas, options = {}) {
  const api = createAgentApi(Module);
  const seed = options.seed ?? 1;
  const maxTics = options.maxTics ?? 35 * 180;
  const captureEvery = options.captureEvery ?? 2;
  const rows = [];
  api.reset(options.skill ?? 2, options.episode ?? 1, options.map ?? 1, seed);

  let searchSign = 1;
  for (let tic = 0; tic < maxTics; tic += 1) {
    const state = api.state();
    if (!state.ready || state.dead) break;
    const visible = api.enemies().filter(enemy => enemy.visible);
    let action;
    if (visible.length) {
      visible.sort((a, b) => Math.hypot(a.x - state.x, a.y - state.y) - Math.hypot(b.x - state.x, b.y - state.y));
      const target = visible[0];
      const error = signedAngle(Math.atan2(target.y - state.y, target.x - state.x) - doomAngle(state.angle));
      const aligned = Math.abs(error) < 0.055;
      action = { forward: aligned ? 28 : 8, strafe: aligned ? (tic % 70 < 35 ? 18 : -18) : 0,
        turn: Math.round(Math.max(-1, Math.min(1, -error / 0.45)) * 900), fire: aligned, use: false };
    } else if (api.probeMove(40, 0)) {
      action = { forward: 45, strafe: 0, turn: 0, fire: false, use: tic % 35 === 0 };
    } else {
      if (tic % 24 === 0) searchSign *= -1;
      action = { forward: 10, strafe: searchSign * 20, turn: searchSign * 720, fire: false, use: tic % 18 === 0 };
    }
    api.action(action);
    api.step(1);
    api.render();
    if (tic % captureEvery === 0) {
      const row = { schema_version: 1, episode: `e${options.episode ?? 1}m${options.map ?? 1}-seed-${seed}`,
        tick: tic, action, state, enemies: visible, frame: canvas.toDataURL("image/jpeg", 0.86) };
      rows.push(row);
      if (options.onSample) await options.onSample(row);
    }
  }
  return rows;
}
