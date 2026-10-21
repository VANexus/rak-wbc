# simulation

离线仿真用于**验证控制器、生成轨迹、检查碰撞**；不用于训练需要 sim2real 迁移的策略
（见 [`../docs/03-architecture/adr/0002-no-sim2real-onboard-only.md`](../docs/03-architecture/adr/0002-no-sim2real-onboard-only.md)）。

## 目录规划

```text
simulation/
├── mujoco/          # 快速动力学验证、接触回放、轨迹检查
├── gazebo/          # 传感器/场景仿真（可选）
├── models/          # 机器人模型（与 description 同步）
├── worlds/          # 赛道元素：碎石/斜坡/台阶/跨栏/颠簸/窄道
└── scenarios/       # 回归场景：站立/行走/起身/跌倒/负重
```

## 原则

1. 模型参数以实机辨识为准，不用“差不多”的默认值。
2. 仿真指标必须高于真机门槛（经验折损 70–80%）。
3. 每个控制器改动至少跑一遍 MuJoCo 回归，再上真机。
4. 仿真只做验证，不产出部署策略。
