def test_import_package() -> None:
    import rak_wbc_manipulation

    assert rak_wbc_manipulation.__name__ == "rak_wbc_manipulation"


def test_node_module_is_importable() -> None:
    from rak_wbc_manipulation import manipulation_node

    assert callable(manipulation_node.main)
