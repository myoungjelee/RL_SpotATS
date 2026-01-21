# RL_SpotATS – Isaac Lab 기반 Spot ATS 강화학습 프로젝트

> **이 저장소는 실행용 배포물이 아니라, 로봇 강화학습 실험을 설계·구현·운영한 과정을 정리한 포트폴리오용 레포지토리입니다.**
>
> 용량/라이선스/재현성 문제로 인해 **USD 자산, 대형 로그, 체크포인트 파일은 Git에 포함되지 않습니다**.
> (자세한 제외 항목은 `.gitignore` 참고)

---

## 🎯 프로젝트 개요

**RL_SpotATS**는 NVIDIA **Isaac Lab + Isaac Sim** 환경에서
사족보행 로봇(Spot 계열)에 **ATS(Auto Targeting System)** 동작을 결합한
강화학습 실험 프로젝트입니다.

이 프로젝트의 목적은:

- Isaac Lab의 **Extension 기반 구조**를 이해하고
- 원본 코드를 수정하지 않은 상태에서
- **Task / Env / Reward / Agent 설정을 분리 설계**하여
- 하나의 RL 실험을 끝까지 감당할 수 있는지 검증하는 것

즉,

> *"잘 걷게 만들기"*가 아니라
> _"Isaac Lab 기반 RL 실험을 실무적으로 설계·운영할 수 있는가"_
> 를 증명하기 위한 프로젝트입니다.

---

## 🧠 핵심 설계 포인트

### 1. Extension 중심 아키텍처

- 본 프로젝트는 **Python 패키지 중심 구조가 아닌**
  **Isaac Sim Extension 기반 구조**로 설계됨
- `source/RL_SpotATS/` 아래에 `extension.toml`을 두고
  Task / Asset / Config를 Extension 단위로 관리
- 그 결과:
  - `pip install -e .` 없이도
  - Isaac Lab 런처(`isaaclab.sh`)를 통해 Task 자동 등록 가능

👉 **Isaac Lab 설치 이후에는 별도 editable install 없이 동작**

---

### 2. Task 단위 실험 분리

강화학습 실험의 최소 단위를 **Task**로 정의:

- 각 Task는 하나의 실험 가설을 의미
- 보상 함수, 관측 공간, 이벤트 로직을 Task 내부에서만 변경
- 기존 locomotion 구조를 유지한 상태에서
  **ATS 관련 행동 유도만 추가**

```text
spot_ats_velocity/
├─ flat_env_cfg.py    # 환경/관측/액션 설정
├─ mdp/rewards.py    # 보상 함수 설계
├─ mdp/events.py     # 에피소드 이벤트 정의
└─ agents/            # PPO 설정 (RSL-RL / SKRL)
```

---

### 3. 실험 재현을 고려한 로그 구조

실험 결과는 **코드가 아니라 로그/설정/차이(diff)**로 남김:

- `logs/rsl_rl/...`
  - 학습 모델 체크포인트
  - TensorBoard 이벤트
  - ONNX / Torch 정책 export

- `logs/.../params/*.yaml`
  - 실제 학습에 사용된 Env / Agent 설정 스냅샷

- `logs/.../git/*.diff`
  - 해당 실험 시점의 코드 변경 사항

👉 *"이 실험에서 뭐가 달랐는지"*를
**파일 구조만 보고도 추적 가능**하게 설계

---

## 📁 레포지토리 구성 (요약)

```text
RL_SpotATS/
├─ scripts/          # 실행/테스트 스크립트 (train, play, zero-agent)
├─ source/           # Isaac Sim Extension (실제 코드)
│  └─ RL_SpotATS/
│     ├─ assets/     # 로봇/씬 정의 (USD는 Git 제외)
│     └─ tasks/      # 강화학습 Task 구현
├─ logs/             # (Git 제외) 학습 결과/모델/설정
├─ outputs/          # (Git 제외) Hydra 런 로그
└─ README.md
```

---

## 🚫 Git에 포함되지 않는 항목

이 레포지토리는 **결과물 저장소가 아님**을 명확히 하기 위해
다음 항목들을 의도적으로 제외합니다:

- USD / USDC / USDT 등 시뮬 자산
- 학습 로그, 체크포인트, 영상, TensorBoard 데이터
- Docker 아티팩트, 대형 바이너리

이는 `.gitignore`에 명시적으로 관리되고 있으며,
**"실험 결과를 어떻게 관리했는가" 자체가 설계 포인트**입니다.

---

## 📌 이 프로젝트로 어필하고 싶은 것

- Isaac Lab / Isaac Sim 기반 **Extension 구조 이해도**
- 강화학습 실험에서
  - Task 분리
  - Reward 설계
  - 설정/로그 관리
    를 **구조적으로 접근한 경험**

- "코드를 많이 짰다"가 아니라
  **"실험을 통제 가능한 형태로 운영했다"**는 점

---

## 🔚 정리

이 레포지토리는:
s

- ✔ 바로 실행하라고 만든 예제도 아니고
- ✔ 결과 파일을 잔뜩 올린 저장소도 아니며
- ✔ 튜토리얼 복붙 프로젝트도 아닙니다

대신,

> **Isaac Lab 기반 로봇 강화학습 실험을
> 처음부터 끝까지 설계하고 관리할 수 있는지**

를 설명하기 위한 **설계 중심 포트폴리오**입니다.

---
