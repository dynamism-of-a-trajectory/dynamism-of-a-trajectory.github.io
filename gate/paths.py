"""Filesystem locations used by the gate experiments.

Every location can be overridden with the environment variable named in the comment;
scripts/env.sh sets the same defaults for the shell scripts. The defaults assume that the
patched openpi checkout sits next to this repo:

    <parent>/dynamism-of-a-trajectory   this repo
    <parent>/openpi-snmvp               openpi @ 15a9616 + patches/openpi_snmvp_working_tree_2026-09-20.patch
"""
import os

RD = os.path.dirname(os.path.abspath(__file__))  # this directory (gate/)
DYN_ROOT = os.path.dirname(RD)
_PARENT = os.path.dirname(DYN_ROOT)

DYN_DATA = os.environ.get("DYN_DATA", os.path.join(DYN_ROOT, "data"))  # downloaded splats
RUN = os.environ.get("DYN_RUN", os.path.join(DYN_ROOT, "runs"))  # trajectories, logs, scores
OPENPI_SNMVP = os.environ.get("OPENPI_SNMVP", os.path.join(_PARENT, "openpi-snmvp"))
FALSIFY = os.environ.get("FALSIFY_DIR", os.path.join(DYN_ROOT, "third_party", "falsify"))  # judge + scene configs
CKROOT = os.environ.get("CKROOT", os.path.join(OPENPI_SNMVP, "checkpoints", "pi0_gate3"))
SPLATS = os.environ.get("SPLATS", os.path.join(DYN_DATA, "gate_scenes_export"))
VENVPY = os.environ.get("OPENPI_PY", os.path.join(OPENPI_SNMVP, ".venv", "bin", "python"))  # JAX / openpi env
TV = os.environ.get("GSPLAT_PY", "python")  # torch + gsplat env
HFB = os.environ.get("HFB", DYN_ROOT)
NORM = os.path.join(HFB, "assets", "gate_nav")  # action/state normalization used by every server
NORM_STATS = os.path.join(NORM, "norm_stats.json")
LEROBOT = os.environ.get("LEROBOT_GATE_NAV3", os.path.expanduser("~/.cache/huggingface/lerobot/local/gate_nav3"))
