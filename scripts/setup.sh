#!/bin/bash
# Clone openpi next to this repo at the commit the paper used, apply this repo's patch, and put the
# normalization stats where openpi looks for them. Builds no environments; see the README for the two
# Python environments (openpi's uv env, and a torch + gsplat env for rendering).
#   bash scripts/setup.sh
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
set -eu

if [ ! -d "$OPENPI_SNMVP" ]; then
  git clone https://github.com/Physical-Intelligence/openpi.git "$OPENPI_SNMVP"
  git -C "$OPENPI_SNMVP" checkout 15a9616a00943ada6c20a0f158e3adb39df2ccac
  git -C "$OPENPI_SNMVP" apply "$DYN_ROOT/patches/openpi_snmvp_working_tree_2026-09-20.patch"
fi
for d in pi0_gate/local/gate_nav pi0_gate3/local/gate_nav3; do
  mkdir -p "$OPENPI_SNMVP/assets/$d"
  cp "$DYN_ROOT/assets/gate_nav/norm_stats.json" "$OPENPI_SNMVP/assets/$d/"
done

echo "openpi-snmvp: $OPENPI_SNMVP"
