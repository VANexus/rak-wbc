def test_import_package() -> None:
    import rak_wbc_mission

    assert rak_wbc_mission.__name__ == "rak_wbc_mission"


def test_node_module_is_importable() -> None:
    from rak_wbc_mission import mission_node

    assert callable(mission_node.main)
