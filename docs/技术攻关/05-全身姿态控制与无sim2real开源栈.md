# 技术攻关 ⑤ 全身姿态控制与「无 sim2real」开源栈

> **前提变更（相对 `01`/`02`）**
> 1. SDK **全开放**：关节位置/力矩、IMU、足底力、相机、雷达、GNSS 全部可读写。
> 2. **不训练 RL、不做 sim2real**：只有机载算力，没有 GPU 训练集群。
> 3. 目标仍是**国一**，但必须先区分「这届 10/23–24 正赛」和「赛后/下一届完整建设」。
>
> **一句话结论**：走 **模型基 WBC（QP）+ 离线轨迹优化（Crocoddyl/OCS2）+ 在线参数辨识 + 官方步态兜底**。
> RL 在本文里只作为“赛后可选”，不作为赛前依赖。

---

## 0. 时间现实检查（先看这一节）

官方赛程：**10/21–22 集训，10/23–24 正赛**。今天是 **10/21**。

| 时间线 | 能交付什么 | 不能交付什么 |
|---|---|---|
| **T0：今明两天（现场）** | SDK 打通、传感器回传、状态码、任务状态机、日志、官方步态跑通、2–3 个操作动作 | 自研 WBC、MPC、全身姿态库、受控跌倒 |
| **T1：赛后 2–4 周** | Pinocchio + WBC + 质心 MPC 基线、接触辅助 EKF、高程图、Nav2、MoveIt2 | 多接触全身规划、任意位姿转换 |
| **T2：3–6 个月（下一届）** | OCS2 MPC+WBC、Crocoddyl 起身/跌倒轨迹库、loco-manipulation、完整运动图 | — |

> **如果这届就要上场：直接跳到 §7.3 的 48 小时清单。**
> 下面 §1–§6 是 T1/T2 的技术底座，也是你问的“全身姿态操控到底怎么说”的完整答案。

---

## 1. 术语：全身姿态操控到底叫什么

### 1.1 一张中英对照表

| 中文 | 英文 | 说明 |
|---|---|---|
| 全身控制 | Whole-Body Control (WBC) | 把全身关节、接触力放进同一个优化里 |
| 全身操作空间控制 | Whole-Body Operational Space Control (WBOSC) | Khatib/Sentis 体系，用任务空间描述全身 |
| 全身姿态控制 | Whole-Body Posture Control | 控制整个构型，而不只是质心 |
| 全身移动操作 | Whole-Body Loco-Manipulation | 边走边操作（抱人、搬物、投掷） |
| 富接触全身运动 | Contact-Rich Whole-Body Motion | 多肢体同时接触环境（趴、跪、撑） |
| 多接触运动规划 | Multi-Contact Motion Planning | 规划“哪些部位在什么时候接触哪里” |
| 接触模式 / 接触时序 | Contact Mode / Contact Schedule | 当前哪些点接触、何时切换 |
| 混杂自动机 | Hybrid Automaton | 连续动力学 + 离散接触切换的统一模型 |
| 运动基元 / 技能 | Motion Primitive / Skill | 可复用的参数化动作单元 |
| 全身轨迹优化 | Whole-Body Trajectory Optimization | 直接优化整条关节/接触轨迹 |
| 质心动力学 | Centroidal Dynamics | 只关心质心与角动量，降维但保留平衡本质 |
| 任务层级 / 分层 QP | Task Hierarchy / Hierarchical QP | 高优先级任务不被低优先级污染 |
| 自扶正 / 起身 | Self-Righting / Get-Up | 从倒地姿态回到站立 |
| 受控跌倒 / 安全跌倒 | Intentional / Controlled / Safe Falling | 主动选择怎么倒，而不是摔 |
| 受身（柔道） | Breakfall / Ukemi | 最能类比的日常概念：顺势倒地、卸力 |
| 跌倒恢复 | Fall Recovery | 跌倒后的恢复全过程 |
| 接触转换 | Contact Transition | 从一种接触模式切到另一种 |
| 步态相位 | Gait Phase / Phase Variable | 用 0–1 的相位参数化周期运动 |
| 运动混合 | Motion Blending | 两段轨迹在 100–300 ms 内平滑过渡 |
| 任意位姿转换 | Any-to-Any Pose Transition | 站/蹲/跪/坐/趴/仰/侧之间任意切换 |

### 1.2 核心心智模型：不要把「走 / 摔 / 起」当成三个模式

正确的建模是一个**混杂动力学系统**：

```text
状态 = (q, q̇, C, s)
  q : 全身广义坐标（浮动基座 6 + 关节 n）
  C : 当前接触集合 {(body_i, point_i, normal_i)}
  s : 相位变量 ∈ [0,1]，描述当前基元执行到哪
```

- **连续部分**：在固定接触集合 `C` 下，用 WBC/MPC 跟踪任务；
- **离散部分**：当接触集合变化（脚离地、手撑地、躯干着地），切换到新的 `C`；
- **切换条件（guard）**：足底力过阈值、IMU 姿态、关节跟踪误差、相位到 1。

在这个模型里：

| 日常说法 | 系统里的说法 |
|---|---|
| 正常走路 | 接触模式在「左脚支撑 / 右脚支撑 / 双支撑」之间周期切换 |
| 躺下 | 从双足支撑 → 蹲 → 坐 → 躯干/臀部接触的接触转换 |
| 平趴 | 多接触模式：躯干 + 双臂 + 双腿同时接触 |
| 摔倒 | **非计划**的接触集合突变 + 冲击 |
| 起身 | 从多接触模式 → 跪 → 单膝 → 双足支撑的接触转换序列 |
| **故意摔倒** | **计划好的**接触转换基元，目标是“得到一个利于起身的接触姿态” |

> 这就是“像故意摔倒只是为了到达目的位姿”的准确说法：
> **把跌倒当成一种 `fall-to-pose` 的运动基元，而不是失败状态。**
> 柔道里的“受身”是最贴切的类比：不是抵抗倒地，而是选择倒地方式。

### 1.3 姿态谱系（Posture Graph）

把机器人能保持的静态姿态做成一个图，节点是姿态，边是转换基元：

```text
                 ┌──────────┐
                 │  STAND   │
                 └────┬─────┘
          ┌───────────┼───────────┐
          ↓           ↓           ↓
     ┌────────┐  ┌────────┐  ┌────────┐
     │ CROUCH │  │ KNEEL  │  │  SIT   │
     └───┬────┘  └───┬────┘  └───┬────┘
         │           │           │
         └───────────┼───────────┘
                     ↓
              ┌─────────────┐
              │  PRONE/SIDE │  ← 多接触
              │   /SUPINE   │
              └──────┬──────┘
                     ↓
              ┌─────────────┐
              │  ROLL       │  ← 翻滚换面
              └─────────────┘
```

- **节点**：每个姿态的关节构型 + 接触集合 + 支撑多边形；
- **边**：一段带接触时序的轨迹（可用 Crocoddyl 离线生成，也可手写关键帧 + 样条）；
- **任意位姿**：先转到最近的规范姿态，再走图的边。不要试图为无穷多种姿态各训一个策略。

### 1.4 支撑多边形与准静态可行性

对一个姿态，把所有接触点投影到水平面，取凸包 = 支撑多边形。
**准静态可行**的条件是：合质心投影落在支撑多边形内，且留安全裕量。

| 姿态 | 接触点 | 支撑多边形 | 特点 |
|---|---|---|---|
| 站立 | 双足 | 两脚凸包 | 单脚支撑时很小 |
| 跪姿 | 双膝 + 双足/脚背 | 较大 | 起身的中间稳定点 |
| 坐姿 | 臀部 + 双足 | 大 | 最稳的中间态 |
| 平趴 | 躯干 + 双臂 + 双腿 | 很大 | 但要避免压迫头部/相机 |
| 仰卧 | 背部 + 双臂 + 双腿 | 很大 | 起身的第一阶段 |
| 侧卧 | 肩 + 髋 + 单臂 | 窄 | 最容易翻成仰卧/俯卧 |

> **工程判据**：每个关键帧都检查“质心投影到支撑多边形的距离 ≥ 3 cm”。
> 不满足就加一个中间姿态，不要硬插值。

---

## 2. 数学骨架：WBC 到底在解什么

### 2.1 浮动基座动力学

```text
M(q) q̈ + h(q, q̇) = Sᵀ τ + Σ_i J_ciᵀ f_i
```

- `q ∈ R^(6+n)`：浮动基座 6 + 关节 n；
- `M`：广义质量矩阵；`h`：科氏力 + 重力；
- `S`：选择矩阵（电机只驱动关节）；
- `f_i`：第 i 个接触点的力（3 维或 6 维）。

### 2.2 WBC 的 QP 形式（多接触版）

```text
决策变量: q̈, τ, {f_i}

min  Σ_k w_k || J_k q̈ + J̇_k q̇ - a_k^des ||²
     + w_τ ||τ||² + w_f Σ_i ||f_i - f_i^ref||²

约束:
  M q̈ + h = Sᵀτ + Σ_i J_ciᵀ f_i          (动力学)
  τ_min ≤ τ ≤ τ_max                       (力矩限幅)
  q_min ≤ q ≤ q_max                       (关节限位)
  f_i ∈ 摩擦锥_i                           (|f_t| ≤ μ_i f_n, f_n ≥ 0)
  J_ci q̈ + J̇_ci q̇ = 0  (固定接触)         (不打滑)
  接触力平滑: |f_i(k) - f_i(k-1)| ≤ Δf_max  (防冲击)
```

### 2.3 任务优先级（从高到低）

| 优先级 | 任务 | 说明 |
|---|---|---|
| 0（硬约束） | 动力学、摩擦锥、力矩/关节限位、固定接触不打滑 | 不可违反 |
| 1 | 质心/角动量跟踪 | 来自质心 MPC；保命 |
| 2 | 躯干姿态 | 评分“躯干端正”直接对应 |
| 3 | 脚/手接触点位姿 | 支撑脚固定、摆动脚轨迹、手撑位置 |
| 4 | **姿态任务（Posture）** | 期望关节构型或躯干/末端位姿 |
| 5 | 关节正则化 | 靠近名义姿态，提高可解性 |

> **“全身姿态控制”在 WBC 里就是一个 posture task**：
> `a_posture = K_p (q_des - q) - K_d q̇`，权重低于平衡任务。
> 躺/趴/跪时，平衡任务退化为“多接触力分配”，posture task 变成主导。

### 2.4 MPC 与 WBC 的分工

```text
质心 MPC（50–100 Hz）
  输入：质心状态、接触时序、地形高度、摩擦估计
  输出：未来 0.5–1.5 s 的质心轨迹 + 期望接触力
        ↓
WBC（500–1000 Hz）
  输入：MPC 参考 + 当前全身状态 + 接触集合
  输出：关节力矩（或关节位置，取决于 SDK）
```

- MPC 负责“未来往哪走、脚踩哪”；
- WBC 负责“这一毫秒每个关节出多大力”；
- **不要用 WBC 做长时域规划，也不要用 MPC 直接输出关节力矩**。

### 2.5 准静态 vs 动态过渡

| 类型 | 适用 | 方法 | 速度 |
|---|---|---|---|
| 准静态 | 躺下、坐起、跪姿转换 | 关键帧 + 质心投影检查 + 慢速 WBC | 慢但稳 |
| 动态 | 起身、受控跌倒、快速翻滚 | 轨迹优化（Crocoddyl DDP）+ WBC 跟踪 | 快但需模型准 |
| 混合 | 起身最后一段、跌倒落地 | 动态优化 + 冲击吸收 + 准静态收尾 | 推荐 |

> **无 sim2real 时，优先准静态**：把动作放慢，用支撑多边形和力矩裕量换稳定性。
> 代价是时间，但比赛只要求 ≤3 s 起身，准静态 2–2.5 s 完全够。

---

## 3. 三个关键动作怎么做

### 3.1 躺下 / 平趴（Stand → Prone）

**目标**：从站立平滑过渡到多接触俯卧，过程中不砸、不压头、不压相机。

步骤：

1. **下蹲**：双足支撑，质心下降，膝/髋/踝协调；
2. **手撑**：双臂前伸接触地面，形成 4 点支撑（双足 + 双手）；
3. **重心前移**：质心投影进入“双手 + 双足”凸包；
4. **屈膝跪地**：膝盖接触，形成 6 点支撑；
5. **躯干下落**：肘部弯曲缓冲，胸部/腹部接触；
6. **调整**：头转向一侧，手臂放到不压传感器的位置。

控制要点：

- 每个接触点加入时，用 100–200 ms 的力斜坡，避免冲击；
- 手撑阶段用**阻抗控制**（低刚度、高阻尼），不要位置硬顶；
- 头部/相机避让写进姿态任务（posture task 的关节偏好）；
- 全程检查支撑多边形，不满足就加中间帧。

### 3.2 起身（Prone/Supine/Side → Stand）

**推荐顺序（按难度从低到高）**：

```text
仰卧 supine:  仰卧 → 侧翻 → 坐起 → 蹲 → 站
俯卧 prone:   俯卧 → 撑起 → 跪 → 单膝 → 站
侧卧 side:    侧卧 → 仰卧/俯卧 → 接上面
```

**无 RL 的生成方法**：

1. 在 Pinocchio 里建全身模型；
2. 用 Crocoddyl 定义接触时序（如：手撑 → 膝撑 → 足撑），
   代价 = 力矩平方 + 时间 + 关节速度惩罚，约束 = 摩擦锥/关节限位/自碰撞；
3. 解 DDP 得到关节轨迹；
4. 在 MuJoCo 里离线回放，检查穿透/力矩/稳定性（这一步只需笔记本，不是 sim2real）；
5. 真机上用 WBC 跟踪，接触点用力传感器确认；
6. 失败时回退到上一个稳定关键帧，而不是从头再来。

**时间预算（目标 ≤2.5 s，硬指标 ≤3 s）**：

| 阶段 | 时间 |
|---|---|
| 检测 + 姿态分类 | 200 ms |
| 撑起/翻面 | 600–900 ms |
| 跪 → 单膝 | 400–600 ms |
| 单膝 → 站 | 500–700 ms |
| 稳定确认 | 200–300 ms |

> 无 RL 时，动作会比 HUMANUP 那种 1.5 s 慢，但**确定性更好、可调试**。
> 比赛只卡 3 s，2.5 s 是安全区。

### 3.3 受控跌倒（Intentional / Controlled Falling）

这是你问的“像故意摔倒只是为了到达目的位姿”的核心。

**触发条件**（满足任一即考虑）：

- DCM 已经无法被可达步长“捕获”；
- 足底打滑且连续 2 步无法恢复；
- 关节力矩饱和 / 关节限位 / 驱动器过温；
- 前方地形负向突变（浅坑/台阶边缘）且已无法后退；
- 负载导致质心偏移超出稳定裕量。

**决策：往哪倒？**

枚举 4 个方向（前/后/左/右），对每个方向算代价：

```text
cost(dir) = w1·冲击能量
          + w2·损坏风险（头/相机/手/负载）
          + w3·起身时间估计
          + w4·任务损失（是否压到道具/出界）
          + w5·地形风险（碎石/斜坡/水）
```

选最小代价方向。经验规则：

| 场景 | 优选 | 理由 |
|---|---|---|
| 空载、平地 | 侧倒 | 支撑面大，手臂可撑，起身最快 |
| 抱假人 | 后倒/侧倒 | 保护前方负载，避免压到假人 |
| 前方有沟 | 后倒/侧倒 | 绝对不要向前 |
| 狭窄赛道 | 侧倒 | 减少前后向占地 |
| 斜坡 | 向上坡侧倒 | 避免向下滚 |

**跌倒轨迹的四个阶段**：

```text
1. 卸载（Unload）     ：降低关节刚度，手臂准备支撑
2. 导向（Guide）      ：用髋/踝/手臂把身体转向目标接触姿态
3. 冲击（Impact）     ：手臂/臀部先接触，关节力矩限幅，阻抗吸收
4. 耗散（Dissipate）  ：停止反弹，确认稳定，进入 get-up
```

**关键技术**：

- **冲击感知 WBC**：接触瞬间把接触力约束从“硬”改为“软”，用阻抗控制；
- **力矩限幅**：冲击时允许关节短暂卸力，但禁止“剧烈甩动”（比赛 6.2.1）；
- **手臂支撑**：用双臂做“受身”，把冲击分散到手臂 + 臀部，而不是头部/背部；
- **目标姿态选择**：倒下的姿态要利于起身（如侧卧、手臂自由），不是随便倒。

> **这一招的战术价值**：当“继续走”必然摔得很难看时，主动选择一个“可控的摔”，
> 把随机摔倒变成“计划内的接触转换”，起身成功率会高很多。
> 这也是为什么它值得单独做成一个 motion primitive，而不是等摔倒后再说。

### 3.4 任意位姿 → 任意位姿：运动图 + 规范姿态

不要为每个位姿对写一条轨迹。做法：

1. 定义 7 个规范姿态：STAND / CROUCH / KNEEL / SIT / PRONE / SUPINE / SIDE；
2. 为每对相邻姿态生成一条转换基元（离线 Crocoddyl 或手写关键帧）；
3. 运行时先找“当前姿态最近的规范姿态”，再在图上搜路径；
4. 用相位变量 `s` 参数化每条边，WBC 跟踪；
5. 转换处用 100–300 ms 的 smoothstep 混合关节目标与接触力。

```text
current_pose → nearest_canonical → graph shortest path → sequence of primitives
```

这就是“全程连贯”的工程实现：**不是一个大控制器，而是一张可验证的运动图 + 一个统一的 WBC 跟踪器。**

---

## 4. 无 sim2real 怎么补

### 4.1 先澄清：不做 sim2real ≠ 不做仿真

- **sim2real**：在仿真里训练策略，再迁移到真机；
- **离线仿真**：用 MuJoCo/Pinocchio 验证控制器、生成轨迹、检查碰撞。

你完全可以（也应该）在笔记本上跑 MuJoCo 做**轨迹生成与验证**，这不叫 sim2real。
真正要放弃的是“Isaac Lab 4096 env 训练 RL 策略再部署”这条重算力路线。

### 4.2 在线参数辨识清单（替代域随机化的一部分）

| 参数 | 方法 | 频率 |
|---|---|---|
| 机身质量/质心/惯量 | 称重 + 悬挂摆测试 + CAD 对照 | 一次 |
| 关节零位 | 机械限位/工装 + 视觉标记 | 一次/换关节后 |
| 关节摩擦/阻尼 | 正弦扫频，拟合 Stribeck/Coulomb | 一次 |
| 电机力矩常数 | 台架：电流 ↔ 力矩 | 一次/换电机后 |
| 端到端延迟 | 给阶跃指令，测编码器响应 | 一次/每次改链路 |
| 足底力零点 | 空载 2 s 均值 | 每次上电 |
| 负载质量/质心 | 臂关节力矩 − 空载预测 | 200–500 Hz 在线 |
| 地面摩擦 | 足底力切向/法向比 + 打滑事件 | 在线估计 |

> **没有域随机化，就用“参数辨识 + 保守裕量”补**：
> 力矩只用 80% 额定，摩擦锥用 0.6×估计值，步长/步高留 20% 余量。

### 4.3 鲁棒化手段（模型基的“域随机化替代品”）

| 手段 | 作用 |
|---|---|
| 摩擦锥收缩（μ_eff = 0.6 μ_est） | 防打滑 |
| 力矩裕量 20% | 防饱和/过温 |
| 接触力斜坡 + 低通 | 防冲击 |
| 阻抗/导纳控制（手、脚） | 吸收地形误差 |
| 扰动观测器（动量观测器） | 估计外力，补偿负载/碰撞 |
| DCM 捕获点监控 | 提前触发落脚点调整或受控跌倒 |
| 多接触力分配 + 滑移约束松弛 | 防止多接触 QP 不可行 |
| 每步检查 QP 可行性 | 不可行时降级到官方步态/急停 |

### 4.4 用轨迹优化替代 RL

| RL 做的事 | 无 RL 的替代 |
|---|---|
| 学起身动作 | Crocoddyl DDP + 接触时序，离线生成轨迹 |
| 学受控跌倒 | 冲击感知轨迹优化 + 手撑关键帧 |
| 学复杂地形步态 | 官方 SDK 步态 + WBC 姿态补偿 + 落脚点规则 |
| 学负重行走 | 负载估计 + 质心 MPC 后倾补偿 + 降速短步 |
| 学抓取 | 规则式视觉伺服 + 预置抓取位姿（见 `03`） |

> **轨迹优化的前提是模型准**。所以 §4.2 的辨识不是可选项，是前置条件。
> 模型不准时，宁可做慢速准静态，也不要用激进动态动作。

### 4.5 机载算力预算（Jetson Orin NX 16G 级别）

| 模块 | 频率 | 预算 | 备注 |
|---|---|---|---|
| WBC QP（28–40 DoF） | 500–1000 Hz | 0.3–1.0 ms/次 | C++ + Pinocchio + ProxSuite/qpOASES |
| 质心 MPC | 50–100 Hz | 2–5 ms/次 | OCS2/Crocoddyl，1–2 s 时域 |
| 高程图 | 10–30 Hz | 10–30 ms | CUDA（Jetson GPU）或 CPU 降采样 |
| 视觉检测 | 10–30 Hz | 20–50 ms | TensorRT/ONNX |
| 状态估计 EKF | 200–500 Hz | <0.5 ms | C++ |
| 任务状态机 | 1–5 Hz | 忽略 | Python/C++ |

> **实时域只放 WBC + 估计 + 硬件接口**；感知/规划/任务放非实时核。
> 用 `isolcpus` + `chrt` + 无锁队列；ROS2 用 CycloneDDS + 共享内存。

### 4.6 安全网：三层降级

```text
Layer A  官方 SDK 内置步态（最稳，性能最低）
   ↑ 自研 WBC/MPC 失败
Layer B  模型基 WBC + 质心 MPC（可解释，需模型）
   ↑ 感知/规划失败
Layer C  准静态动作库（慢但确定性最高）
```

比赛时的切换原则：**宁可慢，不可摔**。一旦 WBC 的 QP 连续 N 次不可行，立即切 Layer A/C。

---

## 5. 开源栈（按层，含许可证与算力）

> 许可证仅作提示：比赛/研究用途基本不受限；若未来商业化，注意 GPL/LGPL/AGPL。

### 5.1 运行时与中间件

| 组件 | 作用 | 许可 | 备注 |
|---|---|---|---|
| **ROS 2 Jazzy**（Ubuntu 24.04） | 中间件 | Apache-2.0 | LTS 到 2029；若 SDK 只支持 Humble 则用 Humble |
| **ros2_control** + `controller_manager` | 硬件抽象 + 控制器管理 | Apache-2.0 | 自写 `hardware_interface` 接 SDK |
| `realtime_tools` | 实时缓冲 | Apache-2.0 | 实时域必备 |
| `lifecycle_node` / `bondcpp` | 生命周期 + 心跳 | Apache-2.0/BSD-3 | 看门狗 |
| `rmw_cyclonedds_cpp` + `iceoryx` | 零拷贝/共享内存 | EPL-2.0/Apache-2.0 | 大点云/图像 |
| `diagnostic_updater` / `diagnostic_aggregator` | 健康监控 | BSD-3 | 状态码来源 |
| `foxglove_bridge` | 可视化/调试 | MIT/Apache-2.0 | 比 RViz 轻 |
| `rosbag2` + `rosbag2_storage_mcap` | 日志 | Apache-2.0 | 比赛要求日志留存 |
| `ros2_tracing` / LTTng | 延迟分析 | Apache-2.0 | 调实时性 |

**内核**：Ubuntu 24.04 + PREEMPT_RT（x86 直接用 `linux-image-rt`；Jetson 用 JetPack 对应 RT 补丁）。
没有 RT 内核时，至少 `isolcpus` + `threadirqs` + `chrt -f 80`。

### 5.2 数学 / 动力学 / 优化

| 库 | 作用 | 许可 | 算力 |
|---|---|---|---|
| **Eigen3** | 线性代数 | MPL2 | CPU |
| **Pinocchio** | 刚体动力学/运动学 | BSD-2 | CPU，极快 |
| **EigenPy** | Python 绑定 | BSD-2 | — |
| **hpp-fcl** | 碰撞检测 | BSD-3 | CPU |
| **Crocoddyl** | 接触轨迹优化（DDP） | BSD-3 | CPU，离线/在线 10–50 Hz |
| **OCS2** | MPC + WBC 框架 | BSD-3 | CPU，50–100 Hz MPC |
| **TSID** | 任务空间逆动力学 QP | BSD-2 | CPU，1 kHz WBC |
| **CasADi** | 符号优化 | LGPL-3.0 | 离线 |
| **ProxSuite** | QP 求解 | BSD-2 | CPU，快 |
| **qpOASES** | QP 求解 | LGPL-2.1 | CPU，成熟 |
| **OSQP** | QP 求解 | Apache-2.0 | CPU |
| **HPIPM** | 内点法 QP | BSD-2 | CPU，适合 MPC |
| **Drake** | 接触隐式优化 | BSD-3 | CPU，重；离线参考 |
| **MuJoCo** | 物理仿真/验证 | Apache-2.0 | CPU/GPU，离线 |
| **mujoco_mpc (MJPC)** | 预测采样 MPC | Apache-2.0 | CPU，可选在线 |

### 5.3 全身控制 / MPC 框架（重点）

| 框架 | 定位 | 适合你吗 |
|---|---|---|
| **OCS2** | 质心 MPC + WBC，legged_robot 示例 | ⭐ 主选；C++，ROS2 可接 |
| **TSID** | 逆动力学 QP，任务层级 | ⭐ WBC 基线；上手快 |
| **Crocoddyl** | DDP 轨迹优化，接触时序 | ⭐ 起身/跌倒轨迹生成 |
| **Pinocchio** | 底层动力学 | ⭐ 必装 |
| **bipedal-locomotion-framework**（IIT） | 完整人形栈 | 参考；YARP 依赖重 |
| **mc_rtc** | 人形 WBC 框架 | 参考；学习曲线陡 |
| **legged_control** | ROS2 + OCS2 + Pinocchio | 参考；四足改双足 |
| **HugWBC** | RL 全身控制器 | 需 GPU 训练；仅参考 |

> **推荐组合**：`Pinocchio + TSID` 做第一版 WBC；`OCS2` 做 MPC；
> `Crocoddyl` 离线生成起身/跌倒轨迹；`MuJoCo` 离线验证。
> 这条组合全 CPU，Orin NX 能跑。

### 5.4 状态估计 / 定位

| 组件 | 作用 | 许可 | 备注 |
|---|---|---|---|
| **robot_localization** | EKF/UKF + GNSS 融合 | BSD-3 | 双 EKF 方案 |
| `navsat_transform_node` | GNSS → map 系 | BSD-3 | 与上同一包 |
| `nmea_navsat_driver` | NMEA 解析 | BSD-3 | 北斗模块 |
| `imu_tools` | IMU 滤波 | BSD-3 | — |
| **FAST-LIO2** | 激光惯性里程计 | GPL-2.0 | CPU，快 |
| **Point-LIO** | 激光惯性里程计 | GPL-2.0 | 高频，抗抖动 |
| **LIO-SAM** | 激光惯性 SLAM | BSD-3 | 带回环 |
| **VINS-Fusion** | 视觉惯性 | GPL-3.0 | 相机+IMU |
| **OpenVINS** | 视觉惯性 | GPL-3.0 | 研究级 |
| **RTAB-Map** | 视觉/激光 SLAM | BSD-3 | 带回环 |
| `geographic_info` | 坐标转换 | BSD-3 | — |
| `kindr` / `Sophus` | 旋转/李群 | BSD-3/MIT | — |
| **elevation_mapping_cupy** | 2.5D 高程图 | BSD-3 | 需 CUDA；Jetson 可用 |
| **grid_map** | 栅格地图 | BSD-3 | CPU 替代 |

> 密林里 **GNSS 只做全局参考**，横向控制靠 LIO；详见 `02` 的 LiDAR 结论。

### 5.5 感知 / 地形

| 组件 | 作用 | 许可 |
|---|---|---|
| `realsense2_camera` | RealSense 驱动 | Apache-2.0 |
| `depthai_ros_driver` | OAK-D 驱动 | MIT |
| `livox_ros_driver2` | Livox 雷达 | MIT |
| `ouster-ros` | Ouster 雷达 | Apache-2.0 |
| `velodyne` | Velodyne 雷达 | BSD-3 |
| `pcl_ros` / `pcl_conversions` | 点云处理 | BSD-3 |
| `depth_image_proc` / `image_proc` | 深度/图像 | BSD-3 |
| `cv_bridge` / `image_transport` | 图像桥接 | BSD-3 |
| `vision_msgs` | 检测结果消息 | BSD-3 |
| **YOLOX** / **NanoDet** | 轻量检测 | Apache-2.0 |
| **RT-DETR** | 检测 | Apache-2.0 |
| **SegFormer**（HuggingFace） | 语义分割 | Apache-2.0 |
| **MobileSAM** | 轻量分割 | Apache-2.0 |
| `apriltag_ros` | 打卡点/标记 | BSD-2 |
| `aruco_ros` | ArUco 标记 | BSD-3 |
| `PaddleOCR` | 文字/标签 | Apache-2.0 |
| **FoundationPose** | 6D 位姿 | NVIDIA 研究许可 |
| **GraspNet** | 抓取位姿 | Apache-2.0 |

> **颜色识别**（雷区拔线）用 HSV 阈值 + 多曝光融合，比学习模型更稳、更可解释（见 `03`）。

### 5.6 规划 / 导航

| 组件 | 作用 | 许可 |
|---|---|---|
| **Nav2** | 导航框架 | Apache-2.0 |
| `nav2_smac_planner` | Hybrid-A* 全局规划 | Apache-2.0 |
| `nav2_mppi_controller` | MPPI 局部控制 | Apache-2.0 |
| `nav2_costmap_2d` | 代价地图 | Apache-2.0 |
| `nav2_behavior_server` | 恢复行为 | Apache-2.0 |
| **BehaviorTree.CPP** | 任务编排 | Apache-2.0 |
| **MoveIt2** | 机械臂规划 | BSD-3 |
| **OMPL** | 采样规划 | BSD-3 |
| `teb_local_planner` | 局部规划（ROS2 移植） | BSD-3 |
| `grid_map` 插件 | 地形代价层 | BSD-3 |
| **自定义 footstep planner** | 落脚点 A* | 自研 |

> 双足没有成熟的 ROS2 落脚点规划包；用 `footstep_planner`（ROS1）的算法思想自研最实际。
> 台阶/跨障场景才启用，平地直接用 MPPI + WBC 落点跟踪。

### 5.7 操作

| 组件 | 作用 | 许可 |
|---|---|---|
| **MoveIt2** | 运动规划 | BSD-3 |
| `joint_trajectory_controller` | 关节轨迹 | Apache-2.0 |
| `admittance_controller` | 导纳/柔顺 | Apache-2.0 |
| `gripper_action_controller` | 夹爪 | Apache-2.0 |
| **LeRobot** | 模仿学习工具链 | Apache-2.0 |
| **ACT** | 视觉动作策略 | MIT |
| **Diffusion Policy** | 视觉动作策略 | MIT |
| `aruco_ros` / `apriltag_ros` | 视觉标记 | BSD |
| 自研 IBVS | 视觉伺服 | — |

> 无算力训练时，ACT/Diffusion Policy 只用作“已训练权重推理”；
> 赛前 48h 不要碰训练，直接用规则式视觉伺服 + 预置位姿。

### 5.8 仿真 / 验证（离线，不是 sim2real）

| 工具 | 用途 | 许可 |
|---|---|---|
| **MuJoCo** | 动力学验证、接触回放 | Apache-2.0 |
| **mujoco_ros2_control** | ROS2 控制接口 | Apache-2.0 |
| **Gazebo Harmonic** + `ros_gz` | 场景/传感器仿真 | Apache-2.0 |
| **Pinocchio** | 运动学/动力学校核 | BSD-2 |
| **RViz2** | 可视化 | BSD-3 |
| **Foxglove** | 数据回放/调试 | MIT/Apache-2.0 |

### 5.9 日志 / 安全 / 可观测

| 组件 | 作用 | 许可 |
|---|---|---|
| `rosbag2` (MCAP) | 全量日志 | Apache-2.0 |
| `diagnostic_updater` | 健康状态 | BSD-3 |
| `system_monitor` | CPU/内存/温度 | BSD-3 |
| `topic_tools` | 话题转发/限流 | BSD-3 |
| `rqt` / `rqt_plot` | 调试 | BSD-3 |
| 自研 watchdog | 心跳/急停 | — |

### 5.10 工程工具

`colcon`、`rosdep`、`vcstool`、`ros2cli`、`launch_ros`、`pre-commit`、`clang-format`、`clang-tidy`、`cppcheck`、`gtest`、`pytest`、`launch_testing`、Docker/devcontainer。

### 5.11 三档组合（直接照抄）

#### Tier 0：现场 48 小时（10/21–22）

```text
官方 SDK
  └─ ros2_control hardware_interface（自写，位置/力矩透传）
      ├─ joint_state_broadcaster
      ├─ forward_command_controller（关节位置/力矩）
      └─ 官方步态控制器（若 SDK 自带）
传感器：IMU / 足底力 / 相机 / 雷达 / GNSS → ROS2 驱动
状态：robot_localization（EKF + navsat_transform）
任务：Python 状态机 或 BehaviorTree.CPP
日志：rosbag2 + 状态码话题
可视化：foxglove_bridge
```

**不要装**：OCS2、Crocoddyl、MoveIt2、Nav2 全套。48h 装不完。

#### Tier 1：赛后 2–4 周（模型基基线）

```text
Tier 0 +
  Pinocchio + TSID（WBC 1 kHz）
  质心 MPC（OCS2 或自写 LIPM+QP，50 Hz）
  接触辅助 EKF（IMU + 腿运动学 + 足底力）
  elevation_mapping_cupy / grid_map
  Nav2（Smac + MPPI）
  MoveIt2（上肢）
```

#### Tier 2：3–6 个月（完整全身姿态）

```text
Tier 1 +
  Crocoddyl：起身/跌倒/翻滚轨迹库
  多接触 WBC（手/膝/躯干接触）
  运动图 + 相位混合
  OCS2 质心 MPC + 接触时序
  loco-manipulation（负重/搬运）
  在线负载估计 + 自适应后倾
```

### 5.12 许可证提醒

| 许可证 | 库 | 注意 |
|---|---|---|
| GPL-2.0 | FAST-LIO2、Point-LIO | 分发二进制需开源；比赛无碍 |
| GPL-3.0 | VINS-Fusion、OpenVINS | 同上 |
| LGPL-2.1/3.0 | qpOASES、CasADi | 动态链接通常可接受 |
| AGPL-3.0 | Ultralytics YOLOv8 | **商业化最危险**；比赛可用，产品建议换 YOLOX/RT-DETR |
| Apache-2.0 | ROS2/Nav2/MoveIt2/MuJoCo | 最宽松 |

---

## 6. ROS2 包骨架与话题契约

### 6.1 包划分

```text
biped_bringup/            启动文件、参数、URDF
biped_description/        URDF/xacro、mesh、惯性参数
biped_hardware/           ros2_control hardware_interface（接 SDK）
biped_msgs/               自定义消息：RobotStatus、ContactState、Footstep
biped_state_estimation/   浮动基座 EKF、接触/打滑检测
biped_localization/       LIO + GNSS 融合、TF
biped_perception/         相机/雷达驱动、检测、分割
biped_terrain/            高程图、可通行代价
biped_planning/           Nav2 配置、落脚点规划
biped_control/            WBC、MPC、步态调度、运动基元
biped_manipulation/       上肢技能、抓取、视觉伺服
biped_mission/            任务状态机 / BehaviorTree
biped_safety/             看门狗、急停、故障分级
biped_logging/            rosbag2 配置、事件日志
```

### 6.2 关键话题

| 话题 | 类型 | 频率 | 说明 |
|---|---|---|---|
| `/joint_states` | `sensor_msgs/JointState` | 500–1000 Hz | 关节反馈 |
| `/imu/data` | `sensor_msgs/Imu` | 200–1000 Hz | 躯干 IMU |
| `/foot_force/*` | `geometry_msgs/WrenchStamped` | 500–1000 Hz | 每足 |
| `/odom` | `nav_msgs/Odometry` | 200–500 Hz | 局部里程计 |
| `/odometry/filtered` | `nav_msgs/Odometry` | 50–200 Hz | 融合后 |
| `/terrain_map` | `grid_map_msgs/GridMap` | 10–30 Hz | 高程图 |
| `/costmap` | `nav_msgs/OccupancyGrid` | 5–10 Hz | 可通行代价 |
| `/cmd_vel` | `geometry_msgs/Twist` | 10–50 Hz | 高层速度 |
| `/footsteps` | `biped_msgs/FootstepArray` | 5–20 Hz | 落脚点 |
| `/joint_commands` | `std_msgs/Float64MultiArray` | 500–1000 Hz | WBC 输出 |
| `/robot_status` | `biped_msgs/RobotStatus` | 10–50 Hz | 比赛状态码 |
| `/diagnostics` | `diagnostic_msgs/DiagnosticArray` | 1–10 Hz | 健康 |
| `/tf` `/tf_static` | `tf2_msgs/TFMessage` | — | REP-105 |

### 6.3 状态码（比赛硬要求）

```text
NORMAL_WALK / OBSTACLE_CROSS / FALLEN / FAULT / LOW_BATTERY
```

用 `biped_msgs/RobotStatus`，同时在本机屏幕大字显示；断连缓存、恢复补传。

### 6.4 实时域设计

```text
CPU 0-1：Linux 系统 + 网络
CPU 2-3：感知/规划（非实时）
CPU 4：WBC/MPC（SCHED_FIFO 80，isolcpus）
CPU 5：硬件接口/看门狗（SCHED_FIFO 90）
```

- 实时域只做：读传感器 → 状态估计 → WBC → 写关节命令；
- 与非实时域用无锁环形缓冲/共享内存；
- 任何动态分配、日志写盘、ROS 服务调用都禁止在实时线程里。

---

## 7. 国一得分路线

### 7.1 分数结构（人形单项）

```text
100 = 任务 60（5×12）+ 运动质量 10 + 自主技术 20 + 时间 10
```

| 档位 | 任务分 | 运动质量 | 自主 | 时间 | 合计 |
|---|---|---|---|---|---|
| 保底 | 12–26 | 6–8 | 16 | 6–8 | **40–58** |
| 务实 | 26–40 | 8 | 16–18 | 8 | **58–66** |
| 冲奖 | 48–55 | 8–10 | 18–20 | 8–10 | **82–95** |

> 国一通常需要 **80+**。也就是说：**5 个任务至少 4 个拿到“完全通过/有条件通过”，且全程零干预、不摔、不出界。**

### 7.2 任务优先级（投入产出比）

| 顺序 | 任务 | 目标 | 理由 |
|---|---|---|---|
| 1 | 密林穿越 | 12 | 纯行走，官方步态 + 地形感知就能拿 |
| 2 | 雷区侦察 | 7–12 | 拔线动作简单，顺序错也有 7 |
| 3 | 丛林投物 | 7–12 | 抛出圈外也给 7，动作做完就有分 |
| 4 | 收纳急救 | 7–12 | 掉落能自拾取给 7 |
| 5 | 伤员转运 | 0–12 | 取决于假人质量，最后搏 |

### 7.3 48 小时清单（今天/明天）

**今天（10/21）**

- [ ] 确认 SDK 到底开放什么：关节位置/力矩？频率？足底力？IMU？急停？
- [ ] 写 `biped_hardware`：SDK ↔ `ros2_control` 透传，先跑通一个关节正弦
- [ ] 确认官方步态怎么启动/停止/切速度；录一段最稳的行走
- [ ] 确认足底力传感器是否存在；没有就准备鞋垫式压力传感器
- [ ] 确认 GNSS/北斗模块接口，写 NMEA → `/fix` 桥
- [ ] 确认无线急停和物理急停都能触发，且卸力不甩
- [ ] 测量：身高/体重/续航/平地速度/最小转弯半径

**明天（10/22）**

- [ ] 全流程试跑 ≥3 次：起点 → 5 个任务点 → 终点，计时
- [ ] 状态码上屏 + 日志落盘（`/joint_states`、`/odom`、`/robot_status`）
- [ ] 任务状态机：完成/超时/跳过/继续，**没有“放弃”状态**
- [ ] 跌倒自恢复演示：用官方起身或预置动作，计时 ≤3 s
- [ ] 录交付视频：平地/斜坡/碎石各 2 次
- [ ] 技术检查 4 项预演：尺寸/急停/自恢复/传感器
- [ ] 打印问题清单，逐条问组委会（假人质量、物品清单、引线规格、换电规则）

### 7.4 2–4 周清单（赛后，模型基 WBC）

- [ ] Pinocchio 模型 + 参数辨识（质量/质心/摩擦/延迟）
- [ ] TSID WBC 站立 → 原地踏步 → 平地行走
- [ ] 质心 MPC（LIPM + QP）叠加
- [ ] 接触辅助 EKF（足底力置零速度）
- [ ] 高程图 + 可通行代价
- [ ] 运动图：STAND/CROUCH/KNEEL/SIT/PRONE/SUPINE/SIDE
- [ ] Crocoddyl 生成仰卧起身轨迹
- [ ] 受控跌倒：侧倒 + 手撑
- [ ] 负重：负载估计 + 后倾补偿
- [ ] 全流程回归测试 ≥20 轮

### 7.5 五个不要

1. **不要在 48h 内自研 WBC**：装不完、调不稳、风险高。
2. **不要在没有参数辨识的情况下跑动态动作**：模型不准 = 摔。
3. **不要把视觉放进 1 kHz 环**：延迟和抖动会毁掉控制。
4. **不要用“最慢最安全”当目标**：时间分和流畅度会掉。
5. **不要在没有吊架保护的情况下试负重/跌倒**：破坏性远大于空载。

---

## 8. 参考

- Sentis, L. & Khatib, O. *A Whole-Body Control Framework for Humanoids Operating in Human Environments*, ICRA 2006.
- Kajita, S. et al. *Biped Walking Pattern Generation by using Preview Control of Zero-Moment Point*, ICRA 2003.
- Englsberger, J. et al. *Three-Dimensional Bipedal Walking Control Based on Divergent Component of Motion*, IEEE T-RO 2015.
- He, X. et al. *Learning Getting-Up Policies for Real-World Humanoid Robots* (HUMANUP), arXiv:2502.12152.
- HOST: *Learning Humanoid Standing-up Control across Diverse Postures*.
- Gaspard, C. et al. *FRASA: An End-to-End RL Agent for Fall Recovery and Stand-Up of Humanoid Robots*, arXiv:2410.08655.
- Xue, Y. et al. *HugWBC: A Unified and General Humanoid Whole-Body Controller for Versatile Locomotion*, RSS 2025.
- *RPL: Learning Robust Humanoid Perceptive Locomotion on Challenging Terrains*, arXiv:2602.03002.
- Carpentier, J. et al. *The Pinocchio C++ Library*.
- Mastalli, C. et al. *Crocoddyl: An Efficient and Versatile Framework for Multi-Contact Optimal Control*, ICRA 2020.
- Sleiman, F. et al. *A Unified MPC Framework for Whole-Body Dynamic Locomotion and Manipulation* (OCS2), RA-L 2021.
- Disney Research. *Falling with Style: Stylized Falling for Humanoid Robots*.
- 柔道“受身（Ukemi）”概念：受控倒地的日常类比。

---

*本文与 `01`–`04` 的关系：`01`/`02` 的 RL 路线在“无算力、无 sim2real”前提下降级为赛后选项；本文给出赛前可执行的模型基路线。*
