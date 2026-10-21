# rak_wbc_hardware

`ros2_control` 硬件接口，负责把灵犀 X2 官方 SDK 包装成标准的
`hardware_interface::SystemInterface`。

## 必须先确认

- SDK 控制模式：位置 / 速度 / 力矩；最高频率；是否支持流式指令。
- 反馈：关节编码器、IMU、足底力、电池 BMS 的频率与时间戳。
- 急停：软件触发接口；卸力斜坡；是否可读取急停状态。
- 通信：TCP / UDP / CAN / EtherCAT；是否需要实时线程。

## 设计约束

- 实时线程内禁止动态分配、日志写盘、阻塞调用。
- 所有单位统一为 SI（rad、rad/s、N、N·m、m、s）。
- 关节顺序与 `rak_wbc_description` 的 URDF 完全一致。
