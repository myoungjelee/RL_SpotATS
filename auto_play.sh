#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# [1] PARAMETER SETTINGS (실험 관리는 여기서!)
# ==============================================================================
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISAACLAB_SH="$HOME/IsaacLab/isaaclab.sh"
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate isaac

# 기본 설정
DEFAULT_TASK="SpotATS-Velocity-Flat-v0"
DEFAULT_EXP_NAME="spot_flat"
DEFAULT_NUM_ENVS=4
DEFAULT_USE_GUI=false

# 📂 [중요] 타겟 폴더 및 체크포인트 설정
# 비워두면("") 자동으로 최신 항목을 탐색합니다.
DEFAULT_RUN_DIR=""        # 예: "2026-02-02_13-52-32_gait_w14p0_fix14"
DEFAULT_CHECKPOINT=""     # 예: "model_500.pt"

# 경로 조립용 베이스
LOG_BASE_DIR="$PROJECT_ROOT/logs/rsl_rl/$DEFAULT_EXP_NAME"

# ==============================================================================
# [2] PATH RESOLUTION LOGIC
# ==============================================================================
# 1. RUN_DIR 결정 (인자1 > 상수 > 자동최신)
if [ -n "${1:-}" ]; then
    RUN_DIR="$1"
    DIR_MODE="인자 지정"
elif [ -n "$DEFAULT_RUN_DIR" ]; then
    RUN_DIR="$DEFAULT_RUN_DIR"
    DIR_MODE="상수 고정"
else
    RUN_DIR=$(ls -td "${LOG_BASE_DIR}"/*/ 2>/dev/null | head -1 | xargs -I {} basename {})
    DIR_MODE="자동 최신"
fi

# 2. CHECKPOINT_FILE 결정 (인자2 > 상수 > 자동최신)
if [ -n "${2:-}" ]; then
    CHECKPOINT_FILE="$2"
    FILE_MODE="인자 지정"
elif [ -n "$DEFAULT_CHECKPOINT" ]; then
    CHECKPOINT_FILE="$DEFAULT_CHECKPOINT"
    FILE_MODE="상수 고정"
else
    CHECKPOINT_FILE=$(ls -v "${LOG_BASE_DIR}/${RUN_DIR}"/model_*.pt 2>/dev/null | tail -1 | xargs -I {} basename {})
    FILE_MODE="자동 최신"
fi

CHECKPOINT_PATH="${LOG_BASE_DIR}/${RUN_DIR}/${CHECKPOINT_FILE}"

# ==============================================================================
# [3] EXECUTION
# ==============================================================================
if [ ! -f "$CHECKPOINT_PATH" ]; then
    echo "❌ [에러] 파일을 찾을 수 없습니다!"
    echo "   경로: $CHECKPOINT_PATH"
    exit 1
fi

echo "=================================================="
echo "  🕹️  Isaac Lab Play Mode"
echo "=================================================="
echo "  📂 Dir  ($DIR_MODE): $RUN_DIR"
echo "  🎯 File ($FILE_MODE): $CHECKPOINT_FILE"
echo "  🖥️  GUI  : $DEFAULT_USE_GUI | Envs: $DEFAULT_NUM_ENVS"
echo "=================================================="

OPTS=(
    --task "$DEFAULT_TASK"
    --checkpoint "$CHECKPOINT_PATH"
    --num_envs "$DEFAULT_NUM_ENVS"
    --real-time
)

[ "$DEFAULT_USE_GUI" = false ] && OPTS+=(--headless)

cd "$PROJECT_ROOT"
"$ISAACLAB_SH" -p "scripts/rsl_rl/play.py" "${OPTS[@]}"
