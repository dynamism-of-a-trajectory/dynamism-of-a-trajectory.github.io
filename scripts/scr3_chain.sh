#!/bin/bash
# scratch-on-gate_nav3 control: wait for training, then plain-serve six cells.
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
set -u

CK=$CKROOT/gate_scratch3/4999
for k in $(seq 1 480); do [ -d "$CK/params" ] && break; sleep 60; done
[ -d "$CK/params" ] || { echo TRAIN_TIMEOUT > $RUN/ev6_scr3.done; exit 1; }
sleep 60
rm -rf $CKROOT/gate_scratch3/*/train_state
bash $DYN_ROOT/scripts/run_sixcell_plain.sh scr3 $CK 9030 10
