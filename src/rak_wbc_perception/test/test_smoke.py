def test_import_package() -> None:
    import rak_wbc_perception

    assert rak_wbc_perception.__name__ == "rak_wbc_perception"


def test_node_module_is_importable() -> None:
    from rak_wbc_perception import perception_node

    assert callable(perception_node.main)
