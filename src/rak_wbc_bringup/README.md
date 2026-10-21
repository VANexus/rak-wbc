# rak_wbc_bringup

顶层启动包。所有启动都从 `bringup.launch.py` 进入，用 `profile` 选择运行环境与包子集。

## Profile

| profile | 运行环境 | 启动内容 | 典型用途 |
|---|---|---|---|
| `robot` | 真机 | hardware + sensors + 全自主栈 | 比赛 |
| `hardware` | 真机 | `ros2_control` + controllers + 状态估计 | 台架/单关节调试 |
| `sim` | 仿真 | 仿真桥 + 全自主栈 | 控制器验证 |
| `dev` | 本机 | mock hardware + RViz + 选中节点 | 本机开发 |
| `perception` | 本机/真机 | 相机/雷达 + 感知 + 地形 | 只调感知 |
| `replay` | 本机 | rosbag/MCAP 回放 + 选中节点 | 离线复现 |

## 用法

```bash
# 本机开发（默认）
ros2 launch rak_wbc_bringup bringup.launch.py profile:=dev

# 真机全系统
ros2 launch rak_wbc_bringup bringup.launch.py profile:=robot

# 只上硬件
ros2 launch rak_wbc_bringup bringup.launch.py profile:=hardware

# 回放
ros2 launch rak_wbc_bringup bringup.launch.py profile:=replay bag_path:=/path/run.mcap
```

## 设计原则

- **profile 只决定“启动哪些包”**，不改变算法代码。
- 本机开发不依赖真机 SDK：`dev` 用 mock hardware 或 `joint_state_publisher`。
- 真机/仿真共用上层 `state_estimation / terrain / planning / control / mission`。
- 每个 profile 的开关（`use_sim_time`、`start_perception` 等）在各子 launch 中声明。
