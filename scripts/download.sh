#!/bin/bash
# Fetch the released checkpoints and Gaussian-splat scenes from the Hugging Face Hub into the locations
# scripts/env.sh expects (checkpoints under $CKROOT, splats under $SPLATS). Needs `pip install huggingface_hub`.
#   bash scripts/download.sh            # paper checkpoints + splats (~23 GB)
#   bash scripts/download.sh appendix   # also the three mixed-data checkpoints of the appendix (~18 GB)
#   bash scripts/download.sh demos      # also the 100 real demonstrations as per-episode .npz (~6 GB)
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
set -eu
HF_REPO=${HF_REPO:-dynamism-of-a-trajectory/dynamism-of-a-trajectory}
get () { hf download "$HF_REPO" --repo-type model --local-dir "$1" --include "$2"; }

get "$DYN_DATA" "gate_scenes_export/*"
get "$(dirname "$CKROOT")" "pi0_gate3/gate_pin_joint_realonly/*"
get "$(dirname "$CKROOT")" "pi0_gate3/gate_scratch_real/*"
for extra in "$@"; do
  case $extra in
    appendix) for c in gate_pin_joint_gmsig3 gate_scratch3 gate_pin_joint_xswap; do get "$(dirname "$CKROOT")" "pi0_gate3/$c/*"; done ;;
    demos) get "$RD" "data_gate_real/*" ;;
    *) echo "unknown extra: $extra"; exit 2 ;;
  esac
done
