# orthoevol-snakemake

A snakemake workflow for the [OrthoEvol](https://github.com/datasnakes/OrthoEvolution) python package.

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

The lock pins Python dependencies and an inspected OrthoEvolution Git revision.
It does not install BLAST+ or provide per-rule environments. Those deployment
definitions remain part of the planned integration. Do not assume that
installing Python dependencies makes the workflow ready to execute.

For Linux HPC use, create the environment on the target system rather than
copying a macOS `.venv`. Ensure that the environment, its underlying Python
interpreter, and external tools are accessible on compute nodes. Prepare
dependencies before submission and invoke `.venv/bin/snakemake` directly during
execution to avoid implicit package installation. Use site-supported modules
or existing tools for BLAST+ and verify their availability inside a compute
allocation. Database retrieval and taxonomy preparation have separate data
and network requirements.

## Authors

* [Shaurita Hutchins](https://github.com/sdhutchins)
* [Rob Gilmore](https://github.com/grabear)

## Usage

### Simple

#### Install workflow

Clone the git repository and change to directory.

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
