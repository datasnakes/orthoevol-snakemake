"""Retrieve an optional RefSeq selection through OrthoEvolution."""

from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import Any

from OrthoEvol.Tools.ftp import NcbiFTPClient

from download_support import write_manifest


def download_release(
    destination: Path,
    email: str,
    subset: str,
    seqtype: str,
    seqformat: str,
) -> None:
    """Keep extraction serial to match the rule's one-CPU allocation."""
    client = NcbiFTPClient(email=email, max_workers=1)
    try:
        client.getrefseqrelease(
            collection_subset=subset,
            seqtype=seqtype,
            seqformat=seqformat,
            download_path=destination,
            extract=True,
        )
    finally:
        client.close_connection()
    write_manifest(
        destination,
        {"collection_subset": subset, "seqtype": seqtype, "seqformat": seqformat},
    )


def main(job: Any) -> None:
    """Capture package output without hiding transfer or extraction failures."""
    with Path(job.log[0]).open("w") as log_file:
        with redirect_stdout(log_file), redirect_stderr(log_file):
            download_release(
                Path(job.output.release),
                job.params.email,
                job.wildcards.subset,
                job.wildcards.seqtype,
                job.wildcards.seqformat,
            )


if __name__ == "__main__":
    main(snakemake)
