"""Prepare taxonomy through OrthoEvolution inside the rule environment."""

from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import Any

from OrthoEvol.Tools.taxonomy import prepare_taxonomy_database


def main(job: Any) -> None:
    """Rebuild when Snakemake schedules this rule; the package validates the result."""
    with Path(job.log[0]).open("w") as log_file:
        with redirect_stdout(log_file), redirect_stderr(log_file):
            prepare_taxonomy_database(job.output.database, overwrite=True)


if __name__ == "__main__":
    main(snakemake)
