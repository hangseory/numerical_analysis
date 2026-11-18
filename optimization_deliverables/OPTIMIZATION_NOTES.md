# Optimization 파트 전달 자료 (팀원 2 · 황준상)

작성일 2026-11-16. 팀원 3(발표·영상)에게 전달하는 최적화 파트 자료입니다.

## 1. 폴더 구성

| 파일 | 내용 |
|---|---|
| `figures/fig1_fuel_and_shiptime_vs_rc.png` | r_c에 따른 연료와 체감 시간. 최적점이 체감 시간 한도에 걸리는 이유 |
| `figures/fig2_fuel_vs_energy.png` | 에너지 E에 따른 연료. 가장 낮은 가능 에너지(E_crit)가 최적 |
| `figures/fig3_golden_section_convergence.png` | Golden-section 수렴 (구간 0.618배씩 감소) |
| `figures/fig4_original_vs_improved.png` | 기존 방식 vs 개선 방식 연료 비교 (4개 시나리오) |
| `results/optimization_scenarios.csv`, `.md` | 시나리오별 결과 표 |
| `testOptimization.m` | 담당 파일 자체 테스트 (18개, 전부 통과) |
| `makeOptimizationFigures.m` | 위 그림과 표를 다시 만드는 스크립트 |
| `optimizationCfg.m` | GUI 없이 실행할 때 쓰는 설정 (`main.m`의 `missionSettings`와 동일) |

다시 만들기: MATLAB에서 이 폴더로 이동 후 `testOptimization`, `makeOptimizationFigures` 실행.

## 2. 코드 변경 사항 (11/16)

인터페이스(함수 이름, 입력, 출력 구조체 필드)는 명세서 그대로입니다. 다른 팀원 파일은 수정할 필요 없습니다.

**`kerrOptimize.m`: E 격자 → Bisection**
- 기존: E를 14개 격자로 나누고, E마다 r_c만 Golden-section으로 정밀화. E 방향은 격자 위치에 따라 결과가 달라짐 (E 하한 여유값을 바꾸면 연료가 3배까지 달라짐).
- 변경: 연료는 E가 낮을수록 작으므로, 각 r_c에서 가능한 가장 낮은 E를 Bisection으로 직접 찾음.
  1. Bisection ①: 정거장까지 올라가는 궤적이 존재하는 최소 에너지 E_crit(r_c)
  2. Bisection ②: E_crit + 10⁻⁵에서 시작해 체감 시간 한도까지 만족하는 최소 E
  3. r_c 격자 탐색 → Golden-section 정밀화 (이웃 격자점이 불가능해도 정밀화)
  4. 채택 전 nSteps와 2·nSteps 결과 비교 (0.1% 이내일 때만 채택)
- 결과: 기본 입력에서 연료 1,562만 kg → **1,288만 kg (−17.5%)**, r_c 격자를 2배로 해도 같은 해.
- 새 설정 3개 (`kerrOptimize.m` 안에 기본값, `main.m` 수정 불필요): `energyMargin=1e-5`, `energyTolerance=1e-10`, `convergenceTolerance=1e-3`
- 더 이상 쓰이지 않는 설정: `nEnergySamples`, `minEnergyMargin`
- `info`에 발표용 필드 추가: `radii`, `Ecrit`, `Ebest`, `coarseCost`, `goldenBracket`, `goldenX`, `goldenCost`, `transferEvaluations`

**`kerrFuel.m`: rapidity 계산의 반올림 오차 수정**
- 기존: γ = −u₁ᵀgu₂, η = acosh(γ). 원궤도 4-속도 성분이 ~1400이라 큰 수끼리 빼면서 γ에 ~10⁻¹⁰ 오차가 생기고, acosh는 1 근처에서 민감해 추진이 0이어야 할 때도 η ≈ 4.5×10⁻⁶ (연료 6 kg)이 나옴.
- 변경: 단위 4-속도에서 (u₁−u₂)ᵀg(u₁−u₂) = 2(γ−1)이므로 차이 형태로 γ−1을 구하고 `log1p`로 η 계산. 실제 결과는 거의 같고(상대 10⁻⁵ 수준), 0 추진 테스트가 정확히 0이 됨.

원본은 `original_code/`에 보관 (git 기록에도 남아 있음).

**명세서에서 고쳐야 할 곳**: O4 kerrOptimize 설명(E 격자 → Bisection), 시나리오 T의 "672회 coarse evaluation" 문구, O1 수식(acosh → log1p 차이 형태).

## 3. 결과 표 (makeOptimizationFigures 실행 결과)

| Scenario | r_c [r_g] | E | Revolutions | Ship time [d] | Gain [yr] | Propellant [kg] | Original [kg] | Change |
|---|---|---|---|---|---|---|---|---|
| 100 yr / 30.4 d | 1.001665 | 0.975911 | 5.223e+05 | 30.42 | 100.00 | 1.288e+07 | 1.562e+07 | -17.5% |
| 10 yr / 1 yr | 1.211821 | 0.976051 | 4.926e+04 | 365.23 | 10.00 | 9.547e+06 | 1.183e+07 | -19.3% |
| 1000 yr / 1 yr | 1.002229 | 0.975912 | 5.227e+06 | 365.22 | 1000.00 | 1.287e+07 | 1.561e+07 | -17.5% |
| 1 yr / 7 d | 1.022113 | 0.975925 | 5157 | 6.98 | 1.00 | 1.247e+07 | 1.509e+07 | -17.4% |

모든 시나리오에서 체감 시간이 한도에 거의 닿아 있음 → 최적해는 체감 시간 제약이 활성화된 지점.

## 4. 발표 스크립트 초안 (Optimization 파트, 약 1분 30초)

> **Slide: How we minimise the propellant**
>
> Our mission has two design variables: the circular-orbit radius r_c and the energy E of the transfer orbit between the station and that circle.
>
> First, the energy. The lower the transfer energy, the smaller the departure and insertion burns, so the propellant always falls as E decreases (Figure 2). But below a critical energy, E_crit, the ship can no longer climb back out to the station. So for every radius we find E_crit by **bisection**, and use an energy just above it.
>
> Second, the radius. Moving the orbit out from the ISCO lowers the propellant, but it also weakens the time dilation, so the crew needs more time to gain the same hundred years (Figure 1). The best radius is therefore where the ship time just reaches the crew's limit. We locate it with a coarse grid followed by **golden-section search**, which shrinks the bracket by a factor of 0.618 every iteration (Figure 3).
>
> Finally, every accepted solution is recomputed with twice as many RK4 steps, and kept only if the times agree within 0.1 %.
>
> Compared with our first version, which searched E on a fixed grid, this reduces the propellant by about 17 to 19 percent in every scenario we tested, and the answer no longer depends on the grid (Figure 4). For the default mission, 100 years gained in 30.4 days of ship time, the spacecraft needs about 12.9 million kilograms of propellant.

## 5. 예상 질문과 답변 (YouTube 댓글 대비)

**Q1. Is this the global optimum?**
No. It is the best mission we found inside a restricted family: symmetric transfers, prograde circular orbits and four impulsive burns. Within that family, the energy direction is solved exactly by bisection and the radius by golden-section search, and the result does not change when we double the radius grid.
(전역 최적해는 아님. 정해진 궤적 범위 안에서 찾은 최선. 격자를 2배로 해도 결과 동일.)

**Q2. Why golden-section search instead of a gradient method?**
After fixing E by bisection, the problem has a single variable, r_c. The cost function has no simple derivative and becomes infinite where the mission is infeasible, so a derivative-free bracketing method is the safest choice.
(E를 정하면 r_c 1변수 문제가 되고, 불가능 영역은 Inf라 미분 기반 방법이 부적합.)

**Q3. What does bisection assume?**
That the transfer exists above some energy and not below it. We checked this by scanning 400 energies at the optimal radius: feasibility switches exactly once.
(가능/불가능이 E에 대해 한 번만 바뀐다는 가정. 400개 E 샘플로 확인.)

**Q4. Why stay 10⁻⁵ above E_crit instead of exactly at it?**
At E_crit the transfer approaches an unstable circular orbit and the ship would circle forever, so the travel time diverges and the RK4 integration needs ever more steps. 10⁻⁵ costs only 0.3 % more propellant and keeps the result converged.
(경계에서는 궤적이 불안정 원궤도에 가까워져 시간이 발산. 10⁻⁵ 여유는 연료 0.3% 차이.)

**Q5. Why is the propellant so large?**
The circular orbit moves at a large fraction of the speed of light, and even with an assumed exhaust speed of 0.15c the relativistic rocket equation is exponential in the total rapidity. A chemical rocket (about 4.4 km/s) could not do this mission at all.
(원궤도 속도가 광속에 가깝고, 로켓 방정식이 지수 함수라서. 화학 로켓으로는 불가능.)

**Q6. Why is the optimum on the ship-time limit?**
Propellant keeps falling as the orbit moves outward, but time dilation also weakens, so the crew needs longer to gain the target. The cheapest orbit is the outermost one that still fits the crew's time limit.
(바깥 궤도일수록 연료는 적지만 체감 시간이 늘어나서, 한도에 닿는 지점이 최적.)

**Q7. How did you make sure the numbers are not numerical artefacts?**
Every accepted mission is recomputed with twice the RK4 steps; the ship time changes by less than 10⁻⁵ relative even with eight times the steps. We also check that all four-velocities satisfy u·u = −1 and that a zero-impulse test gives exactly zero propellant.
(2배 step 재검증, 8배 step에서도 10⁻⁵ 이내, 4-속도 정규화, 0 추진 테스트.)

## 6. AI 사용 기록

이 폴더의 스크립트, 그래프, 문서와 `kerrOptimize.m`, `kerrFuel.m` 수정은 Claude(Anthropic, Claude Code, 2026-11-13~16)와의 대화로 작성했습니다. 제출 시 과제 지침에 따라 프롬프트 기록을 별도 파일로 포함해야 합니다.
