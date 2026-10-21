# ADR 0003: ROS 2 Lyrical + 14 包布局

- 状态：Accepted
- 日期：2026-10-21

## 背景

本机安装的是 `/opt/ros/lyrical`。官方 SDK 可能只支持特定 ROS 版本（Humble/Jazzy），
需要一层硬件抽象把 SDK 与业务代码隔离。

## 决策

1. 使用 **ROS 2 Lyrical** 作为开发/构建环境；包结构保持与 Jazzy 兼容。
2. 采用 14 个 `rak_wbc_*` 包的单一 monorepo：

```text
msgs / description / hardware / bringup
state_estimation / localization / perception / terrain
planning / control / manipulation / mission
safety / logging
```

3. 所有外部依赖通过 `ros2_control`、`rak_wbc_msgs` 和标准 ROS 消息隔离。
4. 官方 SDK 只允许在 `rak_wbc_hardware` 中出现；其他包不得直接调用 SDK。

## 后果

### 正面

- 业务代码与 SDK 解耦，换平台只改 hardware 包。
- 包边界清晰，便于并行开发与单独测试。
- 14 个包足以覆盖感知–规划–控制–任务全链路，又不过度拆分。

### 负面

- 包数量多，构建/依赖管理成本上升。
- `bringup` 需要维护较多 launch 组合。
- 跨越 Lyrical/Jazzy 的 API 差异需要 CI 覆盖。

## 备选方案

1. **单包**：启动简单，但边界混乱、编译慢、无法独立测试。
2. **按层 5 包**：太粗，感知/控制/任务混在一起。
3. **按算法 30+ 包**：过度拆分，维护成本高。
