# ADR 索引

架构决策记录（ADR）。一条决策一个文件，编号递增；已接受的 ADR 不修改，用新 ADR 取代。

| 编号 | 标题 | 状态 |
|---|---|---|
| [0001](0001-model-based-wbc-over-rl.md) | 模型基 WBC 优先于 RL 主线 | Accepted |
| [0002](0002-no-sim2real-onboard-only.md) | 不做 sim2real，只有机载算力 | Accepted |
| [0003](0003-ros2-lyrical-package-layout.md) | ROS 2 Lyrical + 14 包布局 | Accepted |
| [0004](0004-interface-first.md) | 接口优先：先定 `rak_wbc_msgs` | Accepted |

## 模板

```markdown
# ADR NNNN: 标题

- 状态：Proposed / Accepted / Superseded by ADR-XXXX
- 日期：YYYY-MM-DD

## 背景

## 决策

## 后果

### 正面

### 负面

## 备选方案
```
