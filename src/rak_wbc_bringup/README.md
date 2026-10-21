# rak_wbc_bringup

顶层启动包。比赛/调试只从这里启动，避免每个包各自一套 launch。

## 计划中的 launch

| launch | 用途 |
|---|---|
| `bringup.launch.py` | 真机全系统 |
| `sim.launch.py` | MuJoCo/Gazebo 仿真 |
| `debug.launch.py` | 只启动状态估计 + 控制 + 可视化 |
