# Paths shared by every script in this directory; sourced, not run. Override any of the
# upper-case variables below in your environment. Defaults match gate/paths.py.
DYN_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RD=$DYN_ROOT/gate
DYN_DATA=${DYN_DATA:-$DYN_ROOT/data}
RUN=${DYN_RUN:-$DYN_ROOT/runs}
OPENPI_SNMVP=${OPENPI_SNMVP:-$(dirname "$DYN_ROOT")/openpi-snmvp}
FALSIFY_DIR=${FALSIFY_DIR:-$DYN_ROOT/third_party/falsify}
CKROOT=${CKROOT:-$OPENPI_SNMVP/checkpoints/pi0_gate3}
SPLATS=${SPLATS:-$DYN_DATA/gate_scenes_export}
VENVPY=${OPENPI_PY:-$OPENPI_SNMVP/.venv/bin/python}
TV=${GSPLAT_PY:-python}
HFB=${HFB:-$DYN_ROOT}
FLIGHTS=${FLIGHTS:-$RUN/gate_flights}
export DYN_DATA DYN_RUN=$RUN OPENPI_SNMVP FALSIFY_DIR CKROOT SPLATS OPENPI_PY=$VENVPY GSPLAT_PY=$TV HFB
mkdir -p "$RUN"
