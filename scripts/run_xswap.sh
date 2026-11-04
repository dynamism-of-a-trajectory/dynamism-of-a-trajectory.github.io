#!/bin/bash
# S3 cross-supervised training (2026-08-28): gmsig3 recipe + matched-pair chunk swap
# on real frames (SNMVP_XDOM_SWAP p=0.5). Mixed training throughout — no phases, no drift.
source "$(dirname "${BASH_SOURCE[0]}")/env.sh"
set -u

rm -f $RUN/arm_xswap.done
for k in $(seq 1 180); do [ -f $RUN/realloop.done ] && break; sleep 60; done
[ "$(df -BG --output=avail / | tail -1 | tr -dc 0-9)" -ge 9 ] || { echo DISK_GUARD > $RUN/arm_xswap.done; exit 1; }
for k in $(seq 1 40); do
  u=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits -i 0)
  [ "$u" -lt 2000 ] && break; sleep 15
done
cd $OPENPI_SNMVP
env -u VIRTUAL_ENV PYTHONPATH=$OPENPI_SNMVP/src SNMVP_HEAD=1 \
  SNMVP_ZERO_PAD_ACTIONS=1 SNMVP_PIN_U=$RD/pin_U_mh16.npy SNMVP_HEAD_DETACH=0 \
  SNMVP_HEAD_LAM=0.3 SNMVP_HEAD_GMM=1 SNMVP_PIN_NOISE=1.5 SNMVP_PIN_NOISE_RAND=1 \
  SNMVP_PIN_NOISE_COND=1 SNMVP_XDOM_SWAP=$RUN/xswap_table.npz:0.5 \
  XLA_PYTHON_CLIENT_MEM_FRACTION=0.9 CUDA_VISIBLE_DEVICES=0 \
  $VENVPY scripts/train.py pi0_gate3 \
  --exp-name=gate_pin_joint_xswap --num-train-steps=5000 --lr-schedule.decay-steps=1000000 \
  --save-interval=5000 --seed=42 --no-wandb-enabled --overwrite \
  > $RUN/arm_xswap_train.log 2>&1
bash $DYN_ROOT/scripts/run_xswap_post.sh
# real-anchor suite on the xswap checkpoint
CK=$CKROOT/gate_pin_joint_xswap/4999
cd $RD
env -u VIRTUAL_ENV PYTHONPATH=$OPENPI_SNMVP/src SNMVP_HEAD=1 SNMVP_ZERO_PAD_ACTIONS=1 \
  SNMVP_PIN_U=$RD/pin_U_mh16.npy SNMVP_HEAD_DETACH=0 SNMVP_HEAD_LAM=0.3 SNMVP_HEAD_GMM=1 \
  SNMVP_PIN_NOISE=1.5 SNMVP_PIN_NOISE_RAND=1 SNMVP_PIN_NOISE_COND=1 \
  XLA_PYTHON_CLIENT_PREALLOCATE=true XLA_PYTHON_CLIENT_MEM_FRACTION=0.85 CUDA_VISIBLE_DEVICES=0 \
  $VENVPY synthpin_in_real.py --ckpt $CK \
  --out $RUN/synthpin_xswap.npz > $RUN/synthpin_xswap.log 2>&1
echo ALLDONE >> $RUN/arm_xswap.done
