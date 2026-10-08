# orthoevol-snakemake

A Snakemake workflow for the [OrthoEvol](https://github.com/datasnakes/OrthoEvolution)
Python package.

The workflow is under development. Its default target is incomplete, and the
existing rules still need integration with the pinned OrthoEvolution API.
The directory layout and Python dependency lock do not establish execution
correctness.

## Repository layout

```text
config/
    config.yaml
workflow/
    Snakefile
    rules/
        database_setup.smk
        blast.smk
test.csv
pyproject.toml
uv.lock
```

This follows Snakemake's [recommended workflow structure](https://snakemake.readthedocs.io/en/stable/snakefiles/deployment.html#distribution-and-reproducibility).
Run commands from the repository root. Snakemake discovers `workflow/Snakefile`
automatically. Rule includes are relative to that Snakefile, while configuration
and data paths are relative to the working directory.

As the integration proceeds, Python adapters belong in `workflow/scripts/`,
rule environments in `workflow/envs/`, schemas in `workflow/schemas/`, and tests
in `.tests/`. Workflow defaults belong in `workflow/profiles/default/`; users
select their site execution profile separately with `--profile`.
Generated analysis outputs should go under `results/` and downloaded reference
data under `resources/`. The existing rules' output paths still need migration.
The existing `test.csv` input remains at the root until the package adapter's
accession-path handling is updated.

## Software environments

Snakemake's [installation guide](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html)
currently recommends Pixi and also documents Conda/Mamba and pip installation.
Its [software deployment guide](https://snakemake.readthedocs.io/en/stable/snakefiles/deployment.html)
encourages per-rule Conda environments and supports containers and HPC
environment modules. It recommends a Conda or container alternative when using
site-specific modules.

This repository uses `uv` by project preference for Python dependencies. This
is separate from Snakemake's per-rule software deployment. On a setup host with
network access, prepare the repository-local environment with:

```bash
uv sync --locked --no-dev
```

For the optional Slurm executor plugin, use:

```bash
uv sync --locked --no-dev --extra slurm
```

Analysis dependencies belong in `workflow/envs/orthoevol.yaml`. The download
and BLAST rules use this environment through `conda:` and `script:` directives.
It supplies BLAST+ and the pinned OrthoEvolution package separately from the
launcher. Run with `--software-deployment-method conda` to enable deployment.

For Linux HPC use, create the environment on the target system rather than
copying a macOS `.venv`. Ensure that the environment, its underlying Python
interpreter, and external tools are accessible on compute nodes. Prepare
dependencies before submission and invoke `.venv/bin/snakemake` directly during
execution to avoid implicit package installation. Use site-supported modules
or existing tools for BLAST+ and verify their availability inside a compute
allocation. Database retrieval and taxonomy preparation have separate data
and network requirements.

### Install BLAST+ on Linux

The Conda rule environment supplies BLAST+ for managed workflow jobs. For
standalone BLAST use outside those jobs, prefer the site's BLAST+ module when available. Use the
module name and version documented by your site, then verify `blastn -version`
and `blastdbcmd -version` inside a compute allocation.

If no suitable module is available, the following installs BLAST+ without
administrator access on **Linux x86_64**. Version 2.16.0 matches the draft
workflow environment. This follows [NCBI's Unix installation instructions](https://www.ncbi.nlm.nih.gov/books/NBK52640/)
and requires `curl`, `tar`, and network access. ARM systems require a different
build.

```bash
blast_version="2.16.0"
blast_archive="ncbi-blast-${blast_version}+-x64-linux.tar.gz"
blast_url="https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+"

mkdir -p "$HOME/.local/opt"
curl --fail --location \
    "${blast_url}/${blast_version}/${blast_archive}" \
    --output "$HOME/.local/opt/${blast_archive}"

tar -xzf "$HOME/.local/opt/${blast_archive}" -C "$HOME/.local/opt"
export PATH="$HOME/.local/opt/ncbi-blast-${blast_version}+/bin:$PATH"

blastn -version
blastdbcmd -version
```

The installation directory must be visible to compute nodes. Repeat the module
load or the version assignment and `PATH` export in each batch job before
running the workflow. The export above applies only to the current shell and
its child processes. BLAST reference databases require separate setup.

## Authors

* [Shaurita Hutchins](https://github.com/sdhutchins)
* [Rob Gilmore](https://github.com/grabear)

## Usage

### Simple

#### Install workflow

Clone the git repository and change to directory.

```bash
git clone https://github.com/datasnakes/orthoevol-snakemake.git
cd orthoevol-snakemake
```

#### Configure workflow

Configure the workflow by editing `config/config.yaml`.

#### Execute workflow

The following commands are intended for validation after the rule integration
is complete. The current rules import and initialize package code while loading,
so even a dry run is not yet established as side-effect-free.

##### Inspect the execution plan

```console
.venv/bin/snakemake --dry-run --cores 1
```

##### Execute the workflow locally via

```console
.venv/bin/snakemake --cores 1
```

##### Run a specific rule

```console
.venv/bin/snakemake blastn --cores 1
```

Do not launch production runs until the package adapters and representative
integration tests pass.
