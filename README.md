# rak-wbc

2026 粤港澳大湾区具身智能机器人大赛 · 人形机器人丛林越野赛（全自主组）技术仓库。

- **平台**：灵犀 X2（双足人形，SDK 全开放假设）
- **中间件**：ROS 2 Lyrical（本机 `/opt/ros/lyrical`；包结构兼容 Jazzy）
- **控制路线**：模型基 WBC + 质心 MPC + 离线轨迹优化 + 在线参数辨识
- **约束**：全机载算力；不依赖 sim2real 训练；比赛全程禁止实时遥控

> 当前状态：**骨架完成，算法未实现**。所有 `TODO` 都是有意留下的开发入口。

---

## 快速开始

```bash
source /opt/ros/lyrical/setup.bash
colcon build --symlink-install
source install/setup.bash

# 真机（实现 hardware 之后）
ros2 launch rak_wbc_bringup bringup.launch.py
```

或直接用仓库根目录的 Makefile：

```bash
make build
make test
make clean
```

---

## 仓库结构

```text
rak-wbc/
├── README.md
├── Makefile
├── docs/                       # 规则、策略、架构、技术攻关、交付材料
│   ├── README.md               # 文档总索引
│   ├── 00-README-备赛总览.md
│   ├── 01-规则解读与得分策略.md
│   ├── 02-平台选型与硬件方案.md
│   ├── 03-软件架构方案.md
│   ├── 04-备赛执行清单.md
│   ├── 05-待确认问题清单.md
│   ├── 06-参赛现场准备清单-10.20至10.24.md
│   ├── 07-技术文件v2变更解读与双项目策略.md
│   ├── 03-architecture/        # 本仓库的系统架构、ADR、接口契约
│   ├── 技术攻关/               # 五份技术攻坚文档
│   ├── 交付材料/               # 比赛交付模板
│   └── reference/              # 官方技术文件、方案、通知（PDF）
├── src/                        # ROS 2 包（colcon 直接在这里构建）
│   ├── rak_wbc_msgs/           # 消息/服务/Action
│   ├── rak_wbc_description/    # URDF/xacro、mesh
│   ├── rak_wbc_hardware/       # ros2_control 硬件接口
│   ├── rak_wbc_bringup/        # 顶层 launch
│   ├── rak_wbc_state_estimation/
│   ├── rak_wbc_localization/
│   ├── rak_wbc_perception/
│   ├── rak_wbc_terrain/
│   ├── rak_wbc_planning/
│   ├── rak_wbc_control/
│   ├── rak_wbc_manipulation/
│   ├── rak_wbc_mission/
│   ├── rak_wbc_safety/
│   └── rak_wbc_logging/
├── config/                     # 跨包共享参数
├── hardware/                   # SDK 笔记、接线、标定记录
├── simulation/                 # MuJoCo / Gazebo 场景与验证
├── scripts/                    # bootstrap/build/test/run
├── tools/                      # 脚手架、标定、数据处理
├── tests/                      # 集成测试与场地回归
├── docker/                     # 可复现开发环境
└── .github/workflows/          # CI 骨架
```

---

## 包职责

| 包 | 层 | 职责 | 语言 |
|---|---|---|---|
| `rak_wbc_msgs` | 接口 | 状态码、接触、落脚点、运动基元、任务 Action | CMake/rosidl |
| `rak_wbc_description` | 描述 | URDF/xacro、mesh、传感器 frame | xacro |
| `rak_wbc_hardware` | L0 | SDK ↔ `ros2_control` | C++ |
| `rak_wbc_state_estimation` | L1 | 浮动基座 EKF、接触/打滑检测 | C++ |
| `rak_wbc_localization` | L1 | LIO + GNSS/INS 融合、TF | C++ |
| `rak_wbc_perception` | L2 | 检测、分割、标记、视觉伺服 | Python |
| `rak_wbc_terrain` | L2 | 2.5D 高程图、可通行代价 | C++ |
| `rak_wbc_planning` | L3 | 全局/局部规划、边界、落脚点 | C++ |
| `rak_wbc_control` | L2 | WBC、质心 MPC、步态、运动基元 | C++ |
| `rak_wbc_manipulation` | L4 | 抓、拔、放、抱、投 | Python |
| `rak_wbc_mission` | L5 | 行为树/状态机、时间预算、降级 | Python |
| `rak_wbc_safety` | 横切 | 看门狗、急停、故障分级 | C++ |
| `rak_wbc_logging` | 横切 | rosbag2、事件日志、裁判遥测 | C++ |
| `rak_wbc_bringup` | 集成 | 顶层 launch、参数 | CMake |

详细分层、依赖图、话题契约见 [`docs/03-architecture/system-architecture.md`](docs/03-architecture/system-architecture.md)。

---

## 开发约定

### 命名

- ROS2 包：`rak_wbc_<domain>`，蛇形小写。
- C++ 命名空间：`rak_wbc`。
- 话题：`/snake_case`；服务：`/snake_case`；Action：`/snake_case`。
- frame：`base_link`、`base_footprint`、`odom`、`map`、`imu_link`、`lidar_link`、`camera_link`、`foot_*_link`。

### 实时性

- 1 kHz 控制环放在独立 RT 线程/独立核；禁止动态分配、日志写盘、阻塞调用。
- 感知/规划/任务在非实时核；通过无锁队列/共享内存与 RT 域交换。
- 任何跨域通信都必须有超时和降级路径。

### 接口

- 跨包通信优先使用 `rak_wbc_msgs`，不要在包内私自定义跨包类型。
- 所有传感器数据必须带时间戳；驱动层负责硬件时间 → ROS 时间转换。
- 状态码 `RobotStatus` 是比赛硬要求，任何节点都不得阻塞它。

### 提交

- 一个 PR/提交只做一件事；骨架阶段可以按包拆。
- 提交前跑 `make build`；涉及接口的改动必须同步更新 `docs/03-architecture/system-architecture.md`。
- 不提交 `build/`、`install/`、`log/`、`*.mcap`、`*.bag`。

---

## 路线图

| 阶段 | 目标 | 退出条件 |
|---|---|---|
| **T0 现场 48h** | SDK 打通、状态码、日志、任务状态机、官方步态兜底 | 全流程试跑 ≥3 次，零干预完赛 |
| **T1 赛后 2–4 周** | Pinocchio + TSID WBC、质心 MPC、接触辅助 EKF、高程图、Nav2 | 平地/斜坡/碎石稳定行走，跌倒 ≤3 s 起身 |
| **T2 3–6 个月** | OCS2 MPC+WBC、Crocoddyl 起身/跌倒轨迹库、运动图、loco-manipulation | 任意规范姿态转换、负重行走、5 任务全流程 |

### T0 现场优先级（10/21–10/22）

1. 确认 SDK 控制模式/频率/反馈/急停。
2. 写 `rak_wbc_hardware` 透传，跑通单关节正弦。
3. 状态码上屏 + `rosbag2` 落盘。
4. 任务状态机：完成/超时/跳过/继续，**没有“放弃”**。
5. 跌倒自恢复演示 ≤3 s。

---

## 文档

- [文档总索引](docs/README.md)
- [系统架构](docs/03-architecture/system-architecture.md)
- [技术攻关 ⑤：全身姿态控制与无 sim2real 开源栈](docs/技术攻关/05-全身姿态控制与无sim2real开源栈.md)
- [官方技术文件 v2](docs/reference/粤港澳具身智能机器人丛林越野大赛技术文件v2\(1\).pdf)

---

## 许可证

本仓库暂未选择开源许可证；在正式发布前按团队决定补充。
第三方依赖保留各自许可证，详见系统架构文档的 “Licenses” 一节。
