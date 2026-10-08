"""Check adapter contracts without transferring production reference data."""

import importlib
import inspect
import json
from pathlib import Path
from unittest.mock import Mock

import pytest
from OrthoEvol.Tools.ftp import NcbiFTPClient


@pytest.fixture
def adapters(monkeypatch: pytest.MonkeyPatch) -> tuple[object, object]:
    scripts = Path(__file__).resolve().parents[2] / "workflow" / "scripts"
    monkeypatch.syspath_prepend(str(scripts))
    return (
        importlib.import_module("download_blastdb"),
        importlib.import_module("download_refseqrelease"),
    )


def test_blast_adapter_records_files_and_closes_client(
    adapters: tuple[object, object], tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    client = Mock()
    factory = Mock(return_value=client)
    monkeypatch.setattr(adapters[0], "NcbiFTPClient", factory)
    (tmp_path / "refseq_rna.nsq").write_bytes(b"fixture")
    (tmp_path / "volume.tar.gz.md5").write_text("abc  volume.tar.gz\n")

    adapters[0].download_database(tmp_path, "researcher@example.org", 2)

    factory.assert_called_once_with(email="researcher@example.org", max_workers=2)
    client.getblastdb.assert_called_once_with(
        database_name="refseq_rna",
        download_path=tmp_path,
        extract=True,
        include_taxonomy=True,
    )
    client.close_connection.assert_called_once()
    manifest = json.loads((tmp_path / "workflow-manifest.json").read_text())
    assert manifest["archive_checksums"] == {"volume.tar.gz.md5": "abc  volume.tar.gz"}
    assert {item["name"] for item in manifest["files"]} == {
        "refseq_rna.nsq", "volume.tar.gz.md5"
    }


def test_download_failure_is_not_recorded_as_success(
    adapters: tuple[object, object], tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    client = Mock()
    client.getblastdb.side_effect = OSError("checksum mismatch")
    monkeypatch.setattr(adapters[0], "NcbiFTPClient", Mock(return_value=client))
    with pytest.raises(OSError, match="checksum mismatch"):
        adapters[0].download_database(tmp_path, "researcher@example.org", 1)
    client.close_connection.assert_called_once()
    assert not (tmp_path / "workflow-manifest.json").exists()


def test_refseq_extraction_uses_one_worker(
    adapters: tuple[object, object], tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    client = Mock()
    factory = Mock(return_value=client)
    monkeypatch.setattr(adapters[1], "NcbiFTPClient", factory)
    (tmp_path / "vertebrate_mammalian.1.rna.gbff").write_text("fixture\n")
    adapters[1].download_release(
        tmp_path, "researcher@example.org", "vertebrate_mammalian", "rna", "gbff"
    )
    factory.assert_called_once_with(email="researcher@example.org", max_workers=1)
    client.getrefseqrelease.assert_called_once_with(
        collection_subset="vertebrate_mammalian", seqtype="rna", seqformat="gbff",
        download_path=tmp_path, extract=True,
    )
    client.close_connection.assert_called_once()


def test_pinned_package_accepts_download_arguments() -> None:
    inspect.signature(NcbiFTPClient.getblastdb).bind(
        None, database_name="refseq_rna", download_path=Path("fixture"),
        extract=True, include_taxonomy=True,
    )
