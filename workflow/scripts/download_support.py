"""Record the artifacts returned by the package's download implementations."""

import json
from datetime import datetime, timezone
from importlib.metadata import version
from pathlib import Path


def write_manifest(destination: Path, selection: dict[str, str]) -> None:
    """Inventory downloaded files and preserve package checksum markers."""
    files = []
    checksums = {}
    for path in sorted(destination.rglob("*")):
        if not path.is_file() or path.name == "workflow-manifest.json":
            continue
        relative_path = path.relative_to(destination).as_posix()
        files.append({"name": relative_path, "bytes": path.stat().st_size})
        if path.suffix == ".md5":
            checksums[relative_path] = path.read_text().strip()
    if not files:
        raise ValueError(f"The package produced no files in {destination}.")
    manifest = {
        "selection": selection,
        "retrieved_at": datetime.now(timezone.utc).isoformat(),
        "orthoevol_version": version("OrthoEvol"),
        "archive_checksums": checksums,
        "files": files,
    }
    (destination / "workflow-manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n"
    )
