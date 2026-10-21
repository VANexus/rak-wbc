# config

跨包共享的参数。包内默认参数放在各自的 `config/`；这里只放**全系统**参数。

| 文件 | 内容 |
|---|---|
| `robot.yaml` | 平台几何/质量/自由度/传感器配置 |
| `control.yaml` | WBC/MPC 频率、裕量、限幅 |
| `safety.yaml` | 看门狗超时、急停斜坡、故障阈值 |

## 约定

- 所有参数必须能从 `ros2 param` 动态读取；启动时从 YAML 加载。
- 单位统一 SI。
- 不允许在代码里硬编码平台参数。
- 真机实测值优先于官方 datasheet；每次改动记录到 `hardware/calibration.md`。
