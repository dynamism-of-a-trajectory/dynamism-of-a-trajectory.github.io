# Dynamism of a Trajectory

This repository contains the code behind the paper *Dynamism of a Trajectory*, which steers a quadrotor's
flow-matching policy by writing a coarse movement command into the policy's source noise. The policy is
π0 from [openpi](https://github.com/Physical-Intelligence/openpi), fine-tuned on 100 real demonstrations of a
quadrotor flying through gates, and the experiments run in closed loop inside Gaussian-splat reconstructions
of the two captured rooms as well as on the real drone.

The idea in brief is that π0 generates an action chunk by integrating a learned velocity field from Gaussian
noise toward a clean action, using the interpolant `x_t = t·ε + (1−t)·a`. If we choose an orthonormal basis `U`
for a low-dimensional coarse subspace of the chunk (here cumulative displacements over a few horizons) and
construct the noise as `ε = (I − UUᵀ) g + U c` with `c = Uᵀa` during training, then the coarse component of the
regression target `ε − a` is identically zero, so the flow never has to learn it and a command `c` supplied at
inference passes through to the executed chunk exactly. A small head trained jointly with the flow predicts `c`
from the observation when nobody is steering, and a sketched route or another agent can replace that
prediction when somebody is.

## What is in the repository

The `gate/` directory holds everything specific to the paper, which includes the policy servers
(`serve_gate_pin_joint.py` for our policy with its command head and σ map, and `serve_gate_plain.py`,
`serve_gate_plain_sketch.py` and `serve_gate_sdedit.py` for the π0 baselines with injected sketches, velocity
projection and SDEdit), the closed-loop simulator client that renders the splats and flies the quadrotor
(`gate_rollout_batch.py`, with `gsplat_scene_edit.py` building the moved-gate, figure-eight and centre-gate
layouts at load time), the judges that score each flight (`gate_success.py` for directional transit through
the gate aperture, `gate_clearance.py` for the 18 cm contact radius, `route_contact.py`, `sketch_track.py` and
`moved_gate_cell.py` for the sketched routes), the agent-in-the-loop harness (`agent_sim_cli.py`,
`agent_judges.py` and the reviewer briefs in `gate/briefs/`), and the scripts that build the command basis, the
σ map and the training data. The figure builders for the paper are in `gate/viz/`.

Small assets that every server needs ship with the code, namely the command basis `gate/pin_U_mh16.npy`, the σ
maps `gate/sigma_map_*.json`, the sketched routes `gate/sketch_*.json`, the episode splits
`gate/gate_*_eps*.json` and the action and state normalization in `assets/gate_nav/norm_stats.json`. The agent
trials reported in the paper are recorded in `gate/agent_eval/*.jsonl`, with each trial's decisions and the
reviewer's log in `gate/agentflight/`, and the appendix's injection scores are in `gate/vproj/`.

The `scripts/` directory has one shell script per experiment. Each sources `scripts/env.sh`, which defines every
path the experiments use, and `docs/REPRODUCE.md` lists which script produced which number in the paper.

The method's changes to openpi (the pinned source noise, the joint command head, the σ-controlled serving path,
and the `pi0_gate` and `pi0_gate3` configs) are kept as a patch against openpi commit `15a9616` in
`patches/openpi_snmvp_working_tree_2026-09-20.patch`. The directional transit judge, the scene and gate
configurations and the wrist-camera overlay come from the falsify flight-evaluation framework, and the small part
of it that these experiments use is included in `third_party/falsify/` with the re-measured gate apertures already
applied.

## Setting up

The experiments were run on Linux with a single 24 GB NVIDIA GPU. `scripts/setup.sh` clones openpi next
to this repository at the right commit, applies the patch and copies the normalization statistics into openpi's
asset directory.

```bash
git clone https://github.com/dynamism-of-a-trajectory/dynamism-of-a-trajectory.github.io dynamism-of-a-trajectory
cd dynamism-of-a-trajectory
bash scripts/setup.sh
```

Two Python environments are needed because the JAX serving stack and the torch renderer do not share
dependencies comfortably. The first is openpi's own environment, built with `uv sync` inside `../openpi-snmvp`
as described in openpi's README, and it runs the servers, training and the transit judge. The second is a torch
environment with [gsplat](https://github.com/nerfstudio-project/gsplat) (we used torch 2.11 with CUDA 12.8 and
gsplat 1.5.3, plus imageio, numpy, scipy, pyyaml, pillow, matplotlib and openpi's `packages/openpi-client`), and
it runs the simulator client, the clearance judge and the figure builders. Point the scripts at the two interpreters with `OPENPI_PY` and
`GSPLAT_PY` if they are not at the defaults given in `scripts/env.sh`.

The checkpoints and the two Gaussian-splat scenes are hosted on the Hugging Face Hub because they are far
larger than a git repository can hold. `bash scripts/download.sh` fetches the two paper checkpoints and the
splats, about 23 GB in all, and `bash scripts/download.sh appendix demos` also fetches the appendix's
mixed-data checkpoints and the 100 real demonstrations. The checkpoints are fine-tunes of π0, so they are
subject to the [Gemma terms of use](https://ai.google.dev/gemma/terms) that cover π0's PaliGemma backbone in
addition to this repository's license.

## Running an experiment

Every location can be overridden by an environment variable, and the defaults in `scripts/env.sh` assume that
openpi sits next to this repository, that downloads go to `data/` and that results go to
`runs/`. With those in place, the following command serves our policy and flies ten trials each through the left
and right gates at a 25-step replan, then writes the transit and clearance verdicts to
`runs/arm_realonly_apc25_scores.txt`.

```bash
bash scripts/run_realonly_apc25.sh realonly 25
```

The π0 counterpart is `scripts/run_scrreal_apc25.sh 25`, and `docs/REPRODUCE.md` lists the remaining cells.
The agent-in-the-loop experiments call the [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI as
the reviewer (`claude -p`, with tool permission prompts disabled so that it can run unattended), so they need
the CLI installed and logged in, and they are best run inside a sandbox or a throwaway machine.

## License

The code in this repository is released under the Apache License 2.0, in `LICENSE`. openpi keeps its own
license, and the released checkpoints are additionally covered by the Gemma terms mentioned above.
