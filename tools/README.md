# tools

| 工具 | 用途 |
|---|---|
| `scaffold_packages.sh` | 生成/补齐 ROS 2 包骨架（幂等） |
| `calibrate_*.py` | 待补：关节零位、足底力零点、IMU 噪声 |
| `bag_to_csv.py` | 待补：MCAP/rosbag 转 CSV 分析 |
| `plot_*.py` | 待补：质心/接触力/ZMP 可视化 |

## 约定

- 所有工具必须能在仓库根目录直接运行。
- 不把原始标定数据提交进 git（放 `hardware/raw/`，已 ignore）。
- 生成的文件写到 `hardware/` 或 `simulation/` 的对应目录。
