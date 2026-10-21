# rak_wbc_description

机器人描述包：URDF/xacro、mesh、传感器坐标系。

## 约定

- `base_link` 为躯干主坐标系；`base_footprint` 投影到地面。
- 所有传感器 frame 命名：`imu_link`、`lidar_link`、`camera_link`、`foot_*_link`。
- 质量/惯量必须来自官方参数或实测，不要用默认值。
