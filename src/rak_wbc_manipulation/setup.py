from setuptools import setup

package_name = 'rak_wbc_manipulation'

setup(
    name=package_name,
    version='0.1.0',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    extras_require={'test': ['pytest']},
    zip_safe=True,
    maintainer='rak-wbc team',
    maintainer_email='team@example.com',
    description='Upper-body skills: grasp, pull, place, carry and throw.',
    license='Proprietary',
    entry_points={
        'console_scripts': [
            # TODO: 'manipulation_node = rak_wbc_manipulation.manipulation_node:main',
        ],
    },
)
