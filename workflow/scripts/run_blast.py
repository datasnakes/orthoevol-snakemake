"""Run OrthoEvolution inside the BLAST rule's software environment."""

from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import Any

from OrthoEvol.Orthologs.Blast import OrthoBlastN


def main(job: Any) -> None:
    """Run against the declared database and propagate package failures."""
    with Path(job.log[0]).open("w") as log_file:
        with redirect_stdout(log_file), redirect_stderr(log_file):
            blast = OrthoBlastN(
                project=job.params.project,
                method=job.params.method,
                save_data=job.params.save_data,
                acc_file=job.input.acc,
                copy_from_package=job.params.copy_from_package,
                database=job.params.database_prefix,
                ref_species=job.params.ref_species,
            )
            blast.run()


if __name__ == "__main__":
    main(snakemake)
