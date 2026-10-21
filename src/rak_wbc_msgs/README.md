# rak_wbc_msgs

rak-wbc 的接口定义包。所有跨包通信优先使用这里的消息/服务/Action，避免各自定义私有类型。

## 消息

| 类型 | 用途 |
|---|---|
| `RobotStatus` | 比赛状态码：正常行走/越障/跌倒/故障/低电量 |
| `ContactState` | 单足接触、打滑、法向力、CoP |
| `Footstep` / `FootstepArray` | 落脚点序列 |
| `MotionPrimitive` | 运动基元指令（站/蹲/跪/趴/起身/受控跌倒） |
| `SetMotionPrimitive` | 切换运动基元 |
| `ExecuteTask` | 任务层 Action |

## 约定

- 所有 header 的 `frame_id` 必须符合 REP-105。
- 时间戳统一用 ROS 时间；硬件时间戳在驱动层转换。
