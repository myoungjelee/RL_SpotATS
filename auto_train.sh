#!/usr/bin/env bash
set -euo pipefail

# --- 프로젝트 루트 기준(이 스크립트가 있는 위치)로 경로 고정 ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- conda 활성화 (비-인터랙티브 쉘에선 이게 없으면 conda activate가 안 먹힘) ---
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate sim

# --- IsaacLab 런처 위치(명제님 환경 기준) ---
ISAACLAB_SH="$HOME/IsaacLab/isaaclab.sh"

# --- 실행 ---
"$ISAACLAB_SH" -p "$PROJECT_ROOT/scripts/rsl_rl/train.py" \
  --task SpotATS-Velocity-Flat-v0 \
  --headless \
  agent.max_iterations=1000 \
  agent.save_interval=50 \
  agent.experiment_name=spot_flat \
  env.scene.num_envs=4096 \
  hydra.run.dir="$PROJECT_ROOT/logs/rsl_rl/spot_flat"


# -- 이어서 실행 --
# "$ISAACLAB_SH" -p "$PROJECT_ROOT/scripts/rsl_rl/train.py" \
#     --task SpotATS-Velocity-Flat-v0 \
#     --headless \
#     --resume \
#     --load_run "2026-01-29_19-51-41" \
#     --checkpoint "model_999.pt" \s
#     --max_iterations 10000 \
#     agent.save_interval=50 \
#     agent.experiment_name="spot_flat" \
#     env.scene.num_envs=4096