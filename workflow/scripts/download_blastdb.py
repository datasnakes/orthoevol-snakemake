"""Download the package's local BLAST database into a rule-owned directory."""

from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import Any

from OrthoEvol.Tools.ftp import NcbiFTPClient

from download_support import write_manifest


def download_database(destination: Path, email: str, workers: int) -> None:
    """Delegate selection, checksum validation, and extraction to OrthoEvolution."""
    client = NcbiFTPClient(email=email, max_workers=workers)
    try:
        client.getblastdb(
            database_name="refseq_rna",
            download_path=destination,
            extract=True,
            include_taxonomy=True,
        )
    finally:
        client.close_connection()
    write_manifest(
        destination,
        {"database": "refseq_rna", "source": "https://ftp.ncbi.nlm.nih.gov/blast/db/"},
    )


def main(job: Any) -> None:
    """Capture package output in the rule log and let exceptions fail the job."""
    with Path(job.log[0]).open("w") as log_file:
        with redirect_stdout(log_file), redirect_stderr(log_file):
            download_database(
                Path(job.output.database), job.params.email, job.params.workers
            )


if __name__ == "__main__":
    main(snakemake)
