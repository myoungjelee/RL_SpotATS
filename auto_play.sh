#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate sim

ISAACLAB_SH="$HOME/IsaacLab/isaaclab.sh"

# 원하는 체크포인트로 바꿔서 쓰면 됨
#CHECKPOINT="$PROJECT_ROOT/logs/rsl_rl/spot_flat/2026-01-29_21-41-54/model_9999.pt"

"$ISAACLAB_SH" -p "$PROJECT_ROOT/scripts/rsl_rl/play.py" \
  --task SpotATS-Velocity-Flat-v0 \
  --headless \
  #--num_envs=1 \
  #--checkpoint "$CHECKPOINT"
