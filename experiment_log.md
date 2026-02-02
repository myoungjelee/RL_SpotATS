# RL_SpotATS – Experiment Log

---

## [2026-01-29] Pre-history | Template-based Long Run

### 목적

- Isaac Lab + Spot + ATS 시스템 전체 파이프라인 구동 확인

### 설정

- 기본 locomotion template
- Iterations: ~10,000

### 관찰 (Observation)

- 전반적인 보행은 유지됨
- hopping / bounding 형태 반복
- 네 발이 동시에 뜨는 구간 다수 관찰
- 시각적으로 불안정해 보이는 보행

### 로그 근거

- air_time 관련 reward 변동성 큼
- base_motion penalty 불안정

### 판단

- 단일 long-run으로는 원인 분리 불가
- 시각적 인상만으로 학습 실패 여부 판단 불가
- 이후 실험부터 controlled sweep 필요성 인지

---

## [2026-01-31] EXP-001 | Gait Weight Sweep (Controlled)

### 목적

- gait weight 단독 변경이 보행 안정성에 미치는 영향 확인

### 실험 설정

- experiment_name: spot_flat
- seed: 42
- num_envs: 4096
- iterations: 3000 (각 실험)

| Run Tag  | Gait Weight |
| -------- | ----------- |
| gait_w6  | 6.0         |
| gait_w10 | 10.0        |
| gait_w14 | 14.0        |

### 관찰 (Observation)

- gait_w6: 전진/대각선 이동 시 hopping 빈번
- gait_w10: hopping / bounding 반복 (baseline과 유사)
- gait_w14: 연속 보행 형태 유지, bounding 거의 관찰되지 않음

### 로그 근거

- gait_w6 / gait_w10:
  - base_motion penalty 급격한 악화 구간 반복
  - air_time variance 큼

- gait_w14:
  - base_motion penalty 상대적으로 안정
  - velocity tracking 유지

### 판단

- gait weight 단독 문제가 아님
- air_time exploit 가능성 확인
- reward term 간 밸런스 이슈로 추정

---

## [2026-01-31] EXP-002 | Reward Structure Fix (fix)

### 목적

- air_time exploit 억제 및 보행 안정성 확보

### 🔧 변경 사항 (Config Diff)

| Parameter          | Before | After |
| ------------------ | ------ | ----- |
| gait.weight        | 10.0   | 10.0  |
| air_time.weight    | 5.0    | 2.0   |
| base_motion.weight | -2.0   | -3.0  |

### 관찰 (Observation)

- hopping / bounding 현상 현저히 감소
- 연속 보행 패턴 안정화
- yaw 및 base 흔들림 감소

### 로그 근거

- air_time variance 감소
- base_motion penalty 분포 안정화
- velocity tracking 성능 유지

### 판단

- exploit 억제가 보행 안정성에 직접적 영향
- 구조 변경 없이 reward 조정만으로 품질 개선 가능

---

## [2026-02-01] EXP-003 | Penalty Softening & High-Payload Adaptation (fix2)

### 목적

- 5kg ATS 상부 하중 환경에 대한 과도한 페널티 완화

### 🔧 변경 사항 (Config Diff)

| Parameter               | Before | After |
| ----------------------- | ------ | ----- |
| air_time.weight         | 2.0    | 1.0   |
| base_motion.weight      | -3.0   | -1.5  |
| base_orientation.weight | -5.0   | -3.0  |

### 관찰 (Observation)

- 관절 jitter 감소
- 보행 동작이 전반적으로 부드러워짐
- 정지 상태에서 미세한 yaw drift 관찰

### 로그 근거

- action_smoothness reward 상승
- base_motion penalty 평균 감소
- error_vel_xy 일부 구간 plateau 발생

### 판단

- 보행 안정성은 확보됨
- 잔존 drift는 제어 임계값 민감도 문제로 판단

---

## [2026-02-01] EXP-004 | Drift Compensation & Precision Tuning (fix3)

### 목적

- 정지 상태 yaw drift 제거
- 고하중 환경에서 정지 정밀도 확보

### 🔧 변경 사항 (Config Diff)

| Parameter          | Before | After |
| ------------------ | ------ | ----- |
| velocity_threshold | 0.2    | 0.05  |
| stand_still_scale  | 8.0    | 12.0  |

### 관찰 (Observation)

- 입력 없음 상태에서 drift 감소
- 회전 명령 시에만 yaw 발생
- 정지/이동 전환 구간에서 미세한 촐랑거림 발생

### 로그 근거

- drift 관련 metric 개선
- action_smoothness reward 하락

### 판단

- 정지 정밀도는 확보됨
- 과도한 민감도로 인한 미세 진동 발생

---

## [2026-02-01] EXP-005 | Precision & Smoothness Balancing (fix3_v2)

### 목적

- 정지 정밀도 유지 상태에서 보행 및 정지 동작의 자연스러움 확보

### 🔧 변경 사항 (Config Diff)

| Parameter                 | Before | After |
| ------------------------- | ------ | ----- |
| velocity_threshold        | 0.05   | 0.08  |
| action_smoothness_penalty | -1.0   | -2.5  |

### 관찰 (Observation)

- 정지 상태 drift 없음
- 촐랑거림 감소
- 보행 및 정지 전환 구간 안정화

### 로그 근거

- action_smoothness reward 회복
- error_vel_xy 안정화

### 판단

- 정밀도와 부드러움 간 트레이드오프 균형 도달

---

## [2026-02-01] EXP-006 | Authority Recovery & Static Hold Reinforcement (fix4)

### 목적

- fix3_v2에서 발생한 비의도성 위치 이동(우측 후방 drift) 제거
- 부드러움보다 정지 명령에 대한 위치 사수력(authority) 우선 복구

### 🔧 변경 사항 (Config Diff)

| Parameter                 | Before | After | Intent           |
| ------------------------- | ------ | ----- | ---------------- |
| stand_still_scale         | 12.0   | 13.0  | 정지 지지력 강화 |
| velocity_threshold        | 0.08   | 0.06  | 정지 판정 정교화 |
| action_smoothness_penalty | -2.5   | -1.5  | 보정 토크 허용   |

### 관찰 (Observation)

- 입력 없음 상태에서 우측/후방 drift 감소
- 정지 상태에서 발 재배치 빈도 감소
- 정지/이동 전환 시 보행 안정성 유지

### 로그 근거

- error_vel_xy 평균 감소
- stand_still 관련 penalty 분포 안정화
- action_smoothness reward 과도한 하락 없이 유지

### 판단

- drift 원인은 policy 붕괴가 아닌 smoothness–authority 우선순위 충돌
- stand-still 지지력 복구를 통해 고하중 환경 정지 명령 해석 안정화

---

## [2026-02-01] EXP-007 | Static Hold Authority Maximization (fix5)

### 목적

- fix4 이후 잔존한 좌측 쏠림 및 정지 상태 위치 이탈 제거
- 고하중(5kg ATS) + 비대칭 관성 환경에서 정지 명령 사수력(authority) 극대화

### 🔧 변경 사항 (Config Diff)

| Parameter               | Before | After | Intent                   |
| ----------------------- | ------ | ----- | ------------------------ |
| stand_still_scale       | 13.0   | 16.0  | 정지 상태 지지력 극대화  |
| base_orientation.weight | -3.0   | -4.0  | 회전 억제 강화           |
| base_motion.weight      | -1.5   | -3.5  | 저속 위치 이탈 강력 억제 |
| velocity_threshold      | 0.06   | 0.04  | 미세 이동도 정지로 판정  |

### 관찰 (Observation)

- error_vel_xy 수치는 감소 경향
- 실제 보행에서 hopping(콩콩 보행) 재발
- 정지 상태에서 우측 yaw drift 재발

### 로그 근거

- joint torque 및 joint velocity에서 불연속적 피크 관측
- base_orientation penalty 급격한 스파이크 구간 존재

### 판단

- 과도한 강성(high-gain)으로 인해 지면 충격 흡수 실패
- authority 극대화 전략이 보행 유연성을 붕괴시키는 한계점 확인

---

## [2026-02-01] EXP-008 | Compliance Relaxation & Oscillation Diagnosis (fix6)

### 목적

- EXP-007(fix5)의 과도한 강성(high-gain)으로 인한 hopping 완화 시도
- 정지 상태에서 발생한 yaw drift 및 국부 관절 떨림(jitter) 원인 규명
- 강성 완화가 실제 안정화로 이어지는지 검증

### 🔧 변경 사항 (Config Diff)

| Parameter               | Before (fix5) | After (fix6) | Intent                |
| ----------------------- | ------------- | ------------ | --------------------- |
| stand_still_scale       | 16.0          | 14.0         | 과도한 정지 강성 완화 |
| velocity_threshold      | 0.04          | 0.05         | 정지 판정 완화        |
| base_motion.weight      | -3.5          | -3.0         | 저속 미세 보정 허용   |
| base_orientation.weight | -4.0          | -3.5         | yaw 보정 유연성 확보  |

### 관찰 (Observation)

- **이동 시 hopping 현상 지속**
- 정지 상태에서 **좌측 yaw 회전 발생**
- 좌측 전방 다리에서 **지속적인 미세 떨림(jitter)** 관찰
- 드리프트가 누적되는 형태가 아니라  
  **자세 보정이 반복적으로 오버슈트되는 진동(oscillation) 양상**

### 로그 근거

- `error_vel_yaw`:
  - EXP-007 대비 변동성 증가
  - 정지 상태에서도 좌측 방향으로 반복적인 스파이크 발생
- `joint_vel / joint_acc`:
  - 좌측 전방 다리에서 비대칭적인 가속도 피크 지속 발생
- `error_vel_xy`:
  - 평균값은 소폭 감소했으나 안정적 수렴 구간 형성 실패
- `air_time_variance`:
  - hopping 억제 실패 (EXP-005 수준으로 회귀)

### 판단

- EXP-008 실패 원인은 **stand_still_scale 크기 자체가 아님**
- 강성을 낮췄음에도 불구하고:
  - 관절 가속도와 토크 변화율이 제어되지 않아
  - 목표 자세 주변에서 **제어 헌팅(control hunting)** 발생
- 특히 비대칭 하중 환경에서:
  - 좌측 전방 다리에 보정 토크가 집중되며
  - yaw 보정 ↔ 과보정이 반복되는 진동 루프 형성

### 결론

- 현재 문제는
  **“authority vs smoothness” 트레이드오프의 문제가 아니라**
  **“관절 가속도(변화율) 제어 부재로 인한 동적 불안정성”**
- reward weight의 정적 조정만으로는 한계 도달
- 다음 단계에서는
  **joint_acc / torque rate 수준의 댐핑을 직접 제어하는 실험 필요**

---

## [2026-02-01] EXP-009 | Anti-Hunting & Yaw Stabilization (fix7)

### 목적

- EXP-008에서 확인된 정지 상태 헌팅(hunting) 및 좌측 yaw 회전 제거
- 관절 가속도 및 토크 변화율 억제를 통한 진동 안정화
- 비대칭 하중 환경에서 **정지 자세 수렴성 확보**

### 🔧 변경 사항 (Config Diff)

| Parameter                 | Before (fix6) | After (fix7) | Intent                |
| ------------------------- | ------------- | ------------ | --------------------- |
| action_smoothness_penalty | -1.5          | -2.0         | 토크 변화율 강력 억제 |
| joint_acc.weight          | 0.0           | -1e-3        | 관절 가속도 댐핑 추가 |
| base_orientation.weight   | -3.5          | -4.0         | yaw 복원력 강화       |
| base_motion.weight        | -3.0          | -3.5         | 저속 표류 억제 재강화 |
| stand_still_scale         | 14.0          | 14.5         | 정지 지지력 미세 보강 |
| velocity_threshold        | 0.05          | 0.04         | 정지 판정 정밀화      |

### 관찰 (Observation)

- 정지 상태에서 **좌측 앞발 떨림(jitter) 제거**
- yaw 방향 헌팅 현상 소실
- 입력 없음 상태에서 회전 안정성 확보
- 그러나 **로봇 전체가 후방으로 밀리는 선속도 drift 발생**

### 로그 근거

- `error_vel_yaw`:
  - 모든 실험군 중 최저 수준으로 안정화
  - 정지 구간에서 수렴 곡선 형성
- `joint_acc / joint_vel`:
  - 불연속적 피크 제거
  - 좌측 전방 다리 가속도 분산 정상화
- `error_vel_xy`:
  - 시간 경과에 따라 지속적 증가
  - 후방 방향 bias가 명확히 관측됨
- `joint_pos`:
  - 목표 자세를 인지하나, 위치 복구에 실패하는 누적 오차 형태

### 판단

- EXP-009는 **진동 제어에는 성공**
- 그러나:
  - 가속도·부드러움 페널티가 강해
  - 비대칭 하중을 이길 **순간적인 전진 출력(authority)** 부족
- 결과적으로 시스템이
  **“자세는 유지하되, 밀리면 저항하지 않는” under-actuated 상태**로 전이됨

### 결론

- 현재 문제는 더 이상 헌팅이나 회전 불안정이 아님
- 핵심 병목은 **전진 방향 제어 권한 부족**
- 다음 실험에서는:
  - `BASE_MOTION` 제약 완화
  - `GAIT` 가중치 상향을 통해
    **후방 drift를 상쇄할 수 있는 능동적 복원력 확보 필요**

---

## [2026-02-01] EXP-010 | Linear Drift Compensation via Authority Gain (fix8)

### 목적

- EXP-009(fix7)에서 해결된 **진동(Hunting) 및 Yaw 안정성**을 유지한 상태에서
- 비대칭 고하중(5kg ATS)로 인한 **후방 선속도 드리프트(Linear Drift)** 보정
- “자세는 안정적이나 밀리면 저항하지 못하는” under-actuated 상태 탈피

### 🔧 변경 사항 (Config Diff)

| Parameter                 | Before (fix7) | After (fix8) | Intent                            |
| ------------------------- | ------------- | ------------ | --------------------------------- |
| gait.weight               | 10.0          | 12.0         | 전진 명령 추종력 및 동력 확보     |
| base_motion.weight        | -3.5          | -2.5         | 위치 복원을 위한 능동적 이동 허용 |
| action_smoothness_penalty | -2.0          | -1.8         | 전진 토크 출력 여유 확보          |
| joint_acc.weight          | -1e-3         | -1e-3        | 진동 억제 유지                    |
| base_orientation.weight   | -4.0          | -4.0         | yaw 안정성 유지                   |
| stand_still_scale         | 14.5          | 15.0         | 정지 지지력 소폭 보강             |

### 관찰 (Observation)

- EXP-009에서 발생하던 **후방 선속도 drift는 완화되는 경향**
- 그러나:
  - 보행 중 **yaw drift 재발**
  - 다리 스윙이 거칠어지며 보행 품질 저하
- 고하중 상태에서 출력 증가가
  **방향 제어보다 먼저 발현되는 양상** 관찰

### 로그 근거

- `error_vel_xy`:
  - 후방 bias 감소
  - 평균값은 개선되나 분산 증가
- `error_vel_yaw`:
  - EXP-009 대비 상승
  - 특정 구간에서 0.25~0.3 rad/s까지 스파이크 발생
- `joint_acc / action_smoothness`:
  - 가속도 피크 재등장
  - 보행 주기마다 불연속적 변화 관측

### 판단

- EXP-010은 **동력(Authority) 확보에는 성공**
- 그러나:
  - 증가한 출력이 방향/자세 제약에 의해 충분히 제어되지 못함
  - 비대칭 하중 환경에서 yaw 안정성이 다시 병목으로 부상
- 즉,
  **“힘은 생겼으나, 브레이크가 부족한 상태”**

### 결론

- EXP-010을 통해 문제 영역이 명확히 분리됨:
  - 진동/헌팅 ❌ (이미 해결)
  - 전진 동력 ❌ → ⭕ (해결)
  - **방향 안정성 ❌ (재부상)**
- 다음 단계에서는
  - `BASE_ORIENTATION`
  - `JOINT_ACC`
  - `ACTION_SMOOTHNESS`
    를 대폭 강화하여  
    **높아진 출력이 ‘똑바로만’ 쓰이도록 강제하는 실험 필요**

---

## [2026-02-01] EXP-011 | Over-Regulation & Policy Collapse (fix9)

### 목적

- EXP-010(fix8)에서 확인된 “동력은 생겼지만 방향 안정성이 무너지는” 문제를
  강한 제약(orientation/acc/smoothness)으로 억제하여 **고출력 상태에서도 똑바른 보행**을 강제
- 5kg 비대칭 하중 환경에서 **Yaw drift 재발을 근본적으로 차단**하는 방향으로 탐색

### 🔧 변경 사항 (Config Diff)

| Parameter                 | Before (fix8) | After (fix9) | Intent                       |
| ------------------------- | ------------- | ------------ | ---------------------------- |
| gait.weight               | 12.0          | 12.0         | 전진 동력 유지               |
| base_motion.weight        | -2.5          | -4.0         | 저속 표류 강력 억제          |
| base_orientation.weight   | -4.0          | -8.0         | yaw/roll/pitch 복원력 극대화 |
| action_smoothness_penalty | -1.8          | -3.5         | 토크 변화율 강제 댐핑        |
| joint_acc.weight          | -1e-3         | -5e-3        | 관절 가속도 급변 차단        |
| stand_still_scale         | 15.0          | 17.0         | 정지 지지력 최대화           |

### 관찰 (Observation)

- 학습 초반부터 **로봇이 기립 유지에 실패**
- 입력/명령 유무와 무관하게 **빠르게 전복 또는 바닥 접촉으로 종료**
- 정상 보행 탐색이 거의 발생하지 않고 “정지/붕괴”로 수렴

### 로그 근거

- `termination/body_contact` (또는 유사 termination metric):
  - 학습 시작 직후부터 높은 빈도로 발생 (에피소드 조기 종료 폭증)
- reward 계열 그래프:
  - 주요 reward/penalty가 의미 있는 구간을 탐색하지 못하고
    바닥 근처에서 평평하게 유지되는 양상(학습 신호 소실)
- `error_vel_xy`, `error_vel_yaw`:
  - 수렴 형태를 만들기 전에 에피소드가 종료되어
    안정적인 추세/분포를 형성하지 못함

### 판단

- 본 실험은 튜닝 실패가 아니라
  **Penalty 항이 탐색 공간을 압도하여 학습이 성립하지 않는 Policy Collapse**로 분류
- 원인 후보:
  - `base_orientation.weight`와 `action_smoothness_penalty`가 결합되어
    “일단 버티기 위해 필요한 움직임”까지 과벌점 처리
  - 고하중에서 기립/복원에 필요한 순간 출력이
    smoothness/acc 페널티에 의해 차단됨

### 결론

- EXP-011은 “강한 제약으로 고출력 보행을 강제” 전략의 **상한선**을 규정하는 실패 사례이며,
  다음 단계는 동일 목표를 **단계적으로** 달성하는 보수적 리튜닝이 필요

---

## [2026-02-01] EXP-012 | Exploration Collapse after Conservative Re-Tuning (fix10)

### 목적

- EXP-011(fix9)에서 발생한 **Policy Collapse(사지마비)** 복구 시도
- 과도한 규제를 완화하여 에이전트가 다시 보행 탐색(Exploration)을 시작하도록 유도
- fix8에서 확보한 전진 동력을 유지한 상태에서 안정성 회복 가능성 검증

### 🔧 변경 사항 (Config Diff)

| Parameter                 | Before (fix9) | After (fix10) | Intent              |
| ------------------------- | ------------- | ------------- | ------------------- |
| gait.weight               | 12.0          | 12.0          | 전진 출력 유지      |
| base_orientation.weight   | -8.0          | -5.5          | 방향 규제 완화      |
| action_smoothness_penalty | -3.5          | -2.2          | 기립·보행 허용      |
| joint_acc.weight          | -5e-3         | -2e-3         | 가속도 제약 완화    |
| base_motion.weight        | -4.0          | -3.5          | 저속 표류 억제 유지 |
| stand_still_scale         | 17.0          | 15.5          | 정지 강성 완화      |

### 관찰 (Observation)

- 즉각적인 전복 및 종료 현상은 감소
- 그러나:
  - **좌측 전방으로 뒤뚱거리는 비정상 보행 패턴에 고착**
  - 텔레옵 명령 입력 시 전진 대신 제자리 비틀림 반복
- 보행 품질 개선 없이 동일한 패턴이 지속적으로 재현됨

### 로그 근거

- `air_time`, `gait` reward:
  - 다른 실험군(fix7, fix8) 대비 현저히 낮은 수준
  - 탐색 초기에 수렴 없이 정체
- `error_vel_xy`, `error_vel_yaw`:
  - 전체 실험 중 가장 높은 변동성
  - 좌측 전방 bias가 지속적으로 유지됨
- `action_smoothness`, `joint_acc`:
  - 값이 평평하게 높게 유지됨
  - 이는 부드러운 동작이 아니라 **동작 자체를 회피한 결과**

### 판단

- EXP-012는 안정화 실패 이전 단계가 아니라,
  **잘못된 보행 패턴으로의 조기 수렴(Early Bad Convergence)** 상태
- 규제를 완화했음에도:
  - 에이전트가 유효한 보행 패턴을 재탐색하지 못함
  - 5kg 비대칭 하중을 이길 추진력과 탐색 자유도가 모두 부족

### 결론

- EXP-012는 “보수적 재튜닝” 전략의 한계를 명확히 드러냄
- 문제의 본질은 규제 강도 조절이 아니라:
  **탐색 자체가 다시 열리지 않았다는 점**
- 다음 단계에서는:
  - 안정성보다 **전진 동력(GAIT)과 탐색 자유도**를 우선 복구하는
    근본적 방향 전환 필요

---

## [2026-02-02] EXP-013 | Radical Exploration & Gait Power-up (fix11)

### 목적

- EXP-012(fix10)에서 확인된 **Exploration 붕괴 상태** 탈출
- 잘못 수렴된 보행 패턴을 깨고, 에이전트가 다시 “걷는 법”을 탐색하도록 유도
- 안정성보다 **전진 동력과 탐색 자유도 회복**을 우선 목표로 설정

### 🔧 변경 사항 (Config Diff)

| Parameter                 | Before (fix10) | After (fix11) | Intent                                    |
| ------------------------- | -------------- | ------------- | ----------------------------------------- |
| gait.weight               | 12.0           | 14.0          | **[핵심]** 고하중(5kg) 관성을 힘으로 돌파 |
| base_orientation.weight   | -5.5           | -4.5          | 과도한 방향 규제 완화                     |
| action_smoothness_penalty | -2.2           | -1.5          | 탐색 자유도 복구                          |
| joint_acc.weight          | -2e-3          | -1e-3         | 진동 억제 최소 가이드만 유지              |
| base_motion.weight        | -3.5           | -2.0          | 텔레옵 반응성 및 위치 복구 허용           |
| stand_still_scale         | 15.5           | 15.0          | 정지 강성보다 기동성 우선                 |

### 관찰 (Observation)

- **보행 패턴 재등장**
  - EXP-012에서 사라졌던 연속 보행(gait cycle)이 다시 형성됨
- 전진 명령 입력 시:
  - 제자리 비틀림 대신 실제 전진 시도 관측
- 단, 고하중 영향으로:
  - 후반부에 **우측 후방 Drift 및 Yaw 회전 재발**

### 로그 근거

- `gait`, `air_time` reward:
  - EXP-012 대비 명확한 상승
  - 탐색 초반부터 분산된 패턴 생성
- `error_vel_xy`:
  - 최소값 기준 약 **1.25 수준까지 하강**
  - 추진력 자체는 확보됨
- `base_orientation`:
  - 학습 후반부에서 급격한 하락 구간 발생
  - 자세 유지 실패 시점과 Yaw 회전 동기화
- `joint_acc`, `action_smoothness`:
  - 과도한 피크 없이 안정적인 분포 유지

### 판단

- EXP-013은 **Exploration 복구에는 성공**
- 실패 원인은:
  - 출력 부족이나 헌팅이 아닌
  - **비대칭 하중 하에서의 자세 유지 능력 부족**
- 즉,
  - “걷기는 다시 배웠지만,
    허리를 곧게 세우는 법은 아직 미숙한 상태”

### 결론

- EXP-013은 실패 실험이 아니라
  **Phase 전환 성공 지점**
- 정책은 다시 살아났으며,
  이제 문제는 단일 축:
  **Base Orientation 보정**
- 다음 단계에서는:
  - 현재 탐색 성과를 유지한 채
  - Resume 학습을 통해 자세 정밀도만 국소적으로 교정하는 전략이 합리적

---

## [2026-02-02] EXP-014 | Long-run Validation & Residual Diagonal Drift (fix12)

### 목적

- EXP-013(fix11) 이후 **장기 학습(10k)**에서 안정적으로 수렴하는지 검증
- 정지 상태에서 남는 **우측-전방(대각) drift**의 잔존 여부 확인

### 실험 설정

- Tag: fix12
- Iterations: ~10,000
- Resume 여부: (명제님 기록 기준) fix11 성과 계승 형태로 진행

### 🔧 변경 사항 (Config Diff)

| Parameter                 | Before (fix11) | After (fix12) | Intent                                     |
| ------------------------- | -------------- | ------------- | ------------------------------------------ |
| base_orientation.weight   | -4.5           | -5.0          | 자세/방향(특히 yaw) 복원력 강화            |
| action_smoothness_penalty | -1.5           | -1.8          | 급격한 토크 변화 억제(미세 진동/회전 억제) |
| gait.weight               | 14.0           | 14.0          | 전진 동력 유지                             |
| base_motion.weight        | -2.0           | -2.0          | 기동성 유지                                |
| joint_acc.weight          | -1e-3          | -1e-3         | 진동 억제 최소 가이드 유지                 |
| stand_still_scale         | 15.0           | 15.0          | 정지 지지력 유지                           |
| velocity_threshold        | 0.04           | 0.04          | 정지 판정 정밀도 유지                      |

### 관찰 (Observation)

- 장기 학습 구간에서도 **전복/정책 붕괴 없이** 학습이 유지됨
- 전진 추종 성능은 유지/개선되는 느낌
- 그러나 **입력 없음(정지) 상태에서 우측-전방으로 미세 이동**(대각 drift) 잔존
  - “중심이 그쪽으로 잡혀 있는 듯”한 체감 보고

### 로그 근거

- `error_vel_xy`: 장기 구간에서 낮은 값으로 유지/수렴 경향
- `error_vel_yaw`: 완전 소거는 아니며, 정지 구간에서 잔진동/편향 흔적
- `base_orientation`: 큰 붕괴는 없으나 drift 체감과 동기화된 미세 변동 가능성

### 판단

- fix12는 “정상 수렴 가능한 베이스”로 의미가 큼
- 남은 병목은 보행이 아니라 **정지 상태의 편향된 평형점(bias)**

### 결론

- 다음 단계는 새로 학습이 아니라,
  **fix12를 Resume로 이어가며 drift만 국소 교정**하는 전략이 타당

---

## [2026-02-02] EXP-015 | Resume-based Drift Refinement Attempt (fix13)

### 목적

- EXP-014(fix12)의 장기 수렴 성과(추종 성능)를 유지한 채
- 정지 상태에서 남는 **우측-전방 drift bias**가 Resume 학습으로 줄어드는지 확인

### 실험 설정

- Tag: fix13
- Resume: fix12 체크포인트에서 이어 학습
- Iterations: +5,000 (10k → 15k)

### 🔧 변경 사항 (Config Diff)

| Parameter | Before (fix12) | After (fix13) | Intent                                         |
| --------- | -------------- | ------------- | ---------------------------------------------- |
| (동일)    | (동일)         | (동일)        | **웨이트 변경 없이** Resume로 추가 학습만 수행 |

### 관찰 (Observation)

- 체감상 **거동이 크게 바뀌지 않음**
- 정지 상태에서 **우측-전방 drift가 여전히 유지**
- 다만 학습 자체는 계속 성립(붕괴/전복 폭증 형태는 아님)

### 로그 근거

- `error_vel_xy`: 큰 폭의 추가 개선 없이 비슷한 범위에서 유지(plateau 의심)
- `error_vel_yaw`: 일부 구간 개선처럼 보이나 drift 자체를 끊지는 못함
- `base_orientation`: 장기적으로 “나빠지진 않지만”, drift 제거로 이어지지 않음

### 판단

- 동일 reward로 더 오래 돌려도
  drift가 **로컬 최적(습관)으로 고착**되어 plateau일 가능성 큼
- 즉, “시간”이 아니라 **목표(정지 bias)를 더 직접 겨냥하는 신호**가 필요

### 결론

- 여기서 멈추거나,
- 다음은 fix14로 **정지 drift만 타겟하는 최소 변경(5k 짧게)**로 가는 게 효율적

---
