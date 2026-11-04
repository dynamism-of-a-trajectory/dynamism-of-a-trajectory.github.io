# Reproducing the paper's results

This page lists, for each result in the paper, the script that produced it and the checkpoint, sketch and σ
map it reads. All commands are run from the repository root after `scripts/setup.sh` and
`scripts/download.sh`, and every script writes its trajectories, logs and score files to `runs/` (or `$DYN_RUN`).
Each sim cell starts one policy server and one renderer on the same GPU, so cells run one after another.

Our policy is always served by `gate/serve_gate_pin_joint.py` with the same pin settings, which the scripts set
through `SNMVP_*` environment variables (the command head with a Gaussian-mixture readout, the `pin_U_mh16.npy`
basis, residual noise scaled by the σ map, and `SNMVP_NOISE_SEED` for the residual-noise stream). Because the
noise stream is seeded when the server starts, an extension of a cell must use a new seed, otherwise it replays
the earlier trials exactly.

## Table 1, simulation

The demonstrated tasks are the left and right gates, flown at a 25-step replan with 100 trials per arm and side,
in ten batches of ten with one server process and one seed per batch.

| Cell | Command |
|---|---|
| ours, left and right, first 20 | `SEED=0 TRIAL0=1 bash scripts/run_realonly_apc25.sh realonly 25`, then `SEED=1 TRIAL0=11` with the same arguments |
| π0, left and right, first 20 | `bash scripts/run_scrreal_apc25.sh 25`, then the same with `SEED=1 TRIAL0=11` |
| both arms, trials 21 to 100 | `bash scripts/run_to_100.sh` |

The out-of-distribution columns fly routes that never appear in the demonstrations, using sketched commands.

| Cell | Command |
|---|---|
| Arbitrary Gates, ours and the SDEdit and velocity-projection baselines (13 poses, seeds 51 to 63) | `bash scripts/run_reloc_replace.sh "-163,0.04,-1.09 51" "174,2.81,1.37 52" "2,1.06,2.68 53" "153,2.46,-0.3 54" "-58,1.55,1.76 55" "132,1.69,-0.83 56" "-49,-0.06,2.97 57" "44,2.03,2.6 58" "130,0.42,-0.36 59" "-86,2.1,0.87 60" "10,-1.73,2.16 61" "34,-2.6,2.2 62" "107,-1.29,0.24 63"` |
| Orbit Gate, ours (`sketch_orbit_wide.json`, tag `ro25_orbit_wide`) | the hardware-sketch loop of `scripts/run_realonly_reloc_hwsk.sh` |
| Figure-Eight, ours (`sketch_fig8_drawn3_cx15.json`) | `bash scripts/run_fig8_cx15.sh`, with baselines from `scripts/run_fig8_cx15_baselines.sh` |
| π0 with the sketch injected into its source noise, all three OOD columns | `bash scripts/run_pi0_inject_ood.sh` |

The sketches for the 13 moved-gate poses are in `gate/sketch_mg_rr25mg*_{51..63}.json` and can be regenerated
with `gate/moved_gate_cell.py --make`. The pose with seed 60 was widened by hand, and the original is kept as
`..._60_narrow.json`. The OOD cells are scored with
`$GSPLAT_PY gate/score_ood_cells.py --reloc rr25mg --orbit ro25_orbit_wide --fig8 ro25_fig8_drawn3_cx15`, and
`gate/rescore_tables.py` re-derives every Table 1 verdict from the stored trajectories under the patched judge.

The success criterion for a sim flight is a transit through the correct aperture in the correct direction, no
wrong-direction pass, and a clearance of at least 0.18 m from the gate's point cloud.

## Table 1, hardware

The hardware flights used `bash scripts/hw_serve.sh realonly` (or `baseline_real` for π0, and
`--sketch fig8_drawn3` or `--sketch orbit_wide` for the sketched routes) as the policy server, with the drone's
own flight client on a separate workstation. That client and the flight logs are not part of this release, so
these rows cannot be re-run from this repository alone. `scripts/hw_score.sh` scores a directory of flight logs.

## Movement tests and the agent in the loop

The orbit and figure-eight tracking tests at a 50-step replan use `scripts/run_realonly_apps.sh`, scored with
`gate/sketch_track.py`. The hand-drawn left-then-centre compound is the pin arm of `scripts/run_vproj_compare.sh`.

The agent-in-the-loop table runs `bash scripts/run_agent_eval_suite.sh 5 11 sonnet` for the Sonnet trials
11 to 15, and the Opus trials 21 to 25 use `opus` with first trial 21. Each trial renders a brief from
`gate/briefs/common.md` and the task's brief, launches a headless Claude Code reviewer that drives the flight
through `gate/agent_sim_cli.py`, and judges the result with `gate/agent_judges.py`. The waypoint arm serves the
same checkpoint with `SNMVP_PIN_DECODE_ONLY=1`, so it flies the decoded track without denoising. The records
in `gate/agent_eval/` were re-judged with `bash scripts/agent_rejudge.sh 11`. The briefs in `gate/briefs/` are
the latest versions, which differ in a few lines of the double-gate brief from what the paper's trials saw, so
the text as it stood when each trial set ran is kept in `gate/briefs/as_run/trials_11-25/` (the Sonnet trials
11 to 15 and Opus trials 21 to 25) and `gate/briefs/as_run/trials_41-45/` (the double-gate trials 41 to 45).
Copy one of those over `gate/briefs/` to rerun a trial set as it was.

## Appendix

| Result | Scripts |
|---|---|
| sketch injection, SDEdit and velocity projection on π0 at a 50-step replan | `run_vproj_compare.sh`, `run_vproj_sigma.sh`, with scores in `gate/vproj/` |
| flawed sketches on the real-only models | `run_badsketch.sh`, `run_badsketch_vproj_sigma.sh`, `run_worsesketch.sh`, `run_badsketch25.sh`, `run_badgate25.sh` |
| flawed centre-gate sketch on the mixed-data models | `run_badsketch_mix25.sh`, `run_badsketch_mix25_s03.sh`, `run_badsketch_mix25_vps.sh`, scored with `gate/score_badsketch.py` |
| mixed-data atomic tasks | `run_gmsig3_post.sh` for ours, and `run_sixcell_plain.sh scr3` for π0 |
| mixed-data sketches | `run_sketch_drawn.sh`, `run_pin_apps.sh` (cross-swap model), `run_scratch_sketch.sh` and `run_scrsk_fig8.sh` |

The seed-7 replicas of the mixed-data models (`gate_pin_joint_gmsig3s7`, `gate_scratch3s7`) are referenced by
`run_seed_reps2.sh` but are not among the released checkpoints.

## Training

The paper models are trained with openpi's `scripts/train.py pi0_gate3` for 5000 steps on the 100 real
demonstrations (episodes 0 to 99 of the `local/gate_nav3` LeRobot dataset), which `scripts/run_realonly.sh`
does for both arms. Part A trains the plain π0 fine-tune `gate_scratch_real`, and part B trains ours,
`gate_pin_joint_realonly`, with the pin settings listed above. `scripts/run_realonly_post.sh` then fits the σ map
by probing the trained command head (`gate/sigma_phase_probe.py`, then `gate/make_sigma_map.py`). The command
basis `pin_U_mh16.npy` comes from `gate/mh_basis_audit.py`, and it is an orthonormalization of the cumulative
displacements over 6, 12, 25 and 50 steps in x, y, z and yaw. The episode list the training scripts read as
`$RUN/eps_real.json` is `gate/gate_real_eps3.json`.

The mixed-data appendix models add 200 synthetic demonstrations rendered in the splats
(`scripts/regen2_to_gmsig3.sh` builds the dataset and trains `gate_pin_joint_gmsig3`, and `scripts/run_xswap.sh`
trains `gate_pin_joint_xswap`). Rendering those synthetic demonstrations needs the full falsify simulator, of
which only the judge is included here, so these two scripts are documentation of the recipe rather than something
that runs from this repository alone. `gate_scratch3` is the plain `train.py pi0_gate3` recipe on all 300 episodes with
seed 42. The LeRobot dataset itself is built from the captured flights by `gate/gate_v3_to_lerobot.py` and
`gate/build_gate_nav3.py`, and `gate/gate_extract_raw.py` writes the per-episode `.npz` mirrors in
`gate/data_gate_real/` and `gate/data_gate_synth3/` that the probes read.
