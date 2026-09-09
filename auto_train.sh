#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# [1] PARAMETER SETTINGS (여기만 수정하세요)
# ==============================================================================
# # 환경 및 경로
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISAACLAB_SH="$HOME/IsaacLab/isaaclab.sh"
source "$HOME/miniconda3/etc/profile.d/conda.sh"
conda activate isaac

# # 실험 식별 (WandB/Folder 명칭)
EXP_NAME="spot_flat"
SEED=42

# 실험 타입: baseline / fix
EXP_VARIANT="fix"

# #  PARAMETER SETTINGS (여기만 수정하세요)
GAIT_WEIGHT=14.0
AIR_TIME_WEIGHT=1.2
BASE_MOTION_WEIGHT=-2.5
BASE_ORI_WEIGHT=-5.5
ACTION_SMOOTHNESS_WEIGHT=-1.8
JOINT_ACC_WEIGHT=-1e-3
STILL_SCALE=15.0
STILL_THRESH=0.04
RUN_TAG="gait_w${GAIT_WEIGHT//./p}_${EXP_VARIANT}14"

# # 학습 스케줄 및 리소스
NUM_ENVS=4096
SAVE_INTERVAL=50
INITIAL_ITERS=3000

# # 이어하기(Resume) 제어
RESUME=false              # true: 이어하기 / false: 신규 학습
RESUME_ITERS=5000       # 추가 학습 횟수 (기존(10000) + 5000 = 15000 종료)
LOAD_RUN="2026-02-02_10-28-42_gait_w14p0_fix13"     # 불러올 이전 실험 태그
CHECKPOINT=""            # 특정 pt파일 지정 (비우면 최신 checkpoint 자동 로드)

# ==============================================================================
# [2] ARGUMENT ASSEMBLY (인자 조합 로직)
# ==============================================================================
# # 목표 반복 횟수 결정
CURRENT_MAX_ITERS=$INITIAL_ITERS
if [ "$RESUME" = true ]; then
    CURRENT_MAX_ITERS=$RESUME_ITERS
fi

# # 기본 옵션 바구니
OPTS=(
    --task "SpotATS-Velocity-Flat-v0"
    --experiment_name "$EXP_NAME"
    --run_name "$RUN_TAG"
    --seed "$SEED"
    --max_iterations "$CURRENT_MAX_ITERS"
    --num_envs "$NUM_ENVS"
    # --headless
    # --logger "wandb"            # wandb 바로 연동하고싶을때
    --log_project_name "SpotATS"
)

# # 하이드라(Hydra) 오버라이드
HYDRA_OPTS=(
    agent.save_interval="$SAVE_INTERVAL"
    env.rewards.gait.weight="$GAIT_WEIGHT"
)

# fix 실험에서만 보정 적용
if [ "$EXP_VARIANT" = "fix" ]; then
    HYDRA_OPTS+=(
        env.rewards.air_time.weight="$AIR_TIME_WEIGHT"
        env.rewards.base_motion.weight="$BASE_MOTION_WEIGHT"
        env.rewards.base_orientation.weight="$BASE_ORI_WEIGHT"
        env.rewards.action_smoothness.weight="$ACTION_SMOOTHNESS_WEIGHT"
        env.rewards.joint_acc.weight="$JOINT_ACC_WEIGHT"
        env.rewards.joint_pos.params.stand_still_scale="$STILL_SCALE"
        env.rewards.joint_pos.params.velocity_threshold="$STILL_THRESH"
    )
fi

# # 이어하기 옵션 추가
if [ "$RESUME" = true ]; then
    OPTS+=(--resume --load_run "$LOAD_RUN")
    if [ -n "$CHECKPOINT" ]; then
        OPTS+=(--checkpoint "$CHECKPOINT")
    fi
fi

# ==============================================================================
# [3] EXECUTION (실행 및 출력)
# ==============================================================================
echo ">> [MODE] $( [ "$RESUME" = true ] && echo "RESUME" || echo "NEW" )"
echo ">> Running: $EXP_NAME / $RUN_TAG (Target: $CURRENT_MAX_ITERS iters)"

# 학습 실행
"$ISAACLAB_SH" -p "$PROJECT_ROOT/scripts/rsl_rl/train.py" "${OPTS[@]}" "${HYDRA_OPTS[@]}"

# ==============================================================================
# [4] POST-PROCESS (학습 완료 후 처리)
# ==============================================================================
# echo ">> [FINISH] 학습이 완료되었습니다. 1분 후 시스템을 종료합니다."
# echo ">> [CANCEL] 종료를 취소하려면 1분 이내에 'sudo shutdown -c'를 입력하세요."

# # 1분 후 종료 (실수했을 때 취소할 시간을 벌기 위함)
# sudo shutdown -h +1
