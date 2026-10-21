from setuptools import setup

package_name = 'rak_wbc_perception'

setup(
    name=package_name,
    version='0.1.0',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='rak-wbc team',
    maintainer_email='team@example.com',
    description='Camera/LiDAR perception: detection, segmentation, markers and visual servoing.',
    license='Proprietary',
    entry_points={
        'console_scripts': [
            # TODO: 'perception_node = rak_wbc_perception.perception_node:main',
        ],
    },
)
