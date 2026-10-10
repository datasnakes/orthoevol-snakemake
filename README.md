# orthoevol-snakemake

A Snakemake workflow for the [OrthoEvol](https://github.com/datasnakes/OrthoEvolution)
Python package.

The workflow is under development and is testing the OrthoEvolution `snakemake-fixes` branch.
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
environment.yml
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

For Linux/HPC, `environment.yml` defines the launcher environment with Python
3.12, Snakemake 9.27.0, and Slurm executor plugin 2.8.0. Miniforge must provide
`conda` in its base environment for Snakemake's Conda integration. Site-specific
Slurm account, partition, and submission limits belong in a site profile.

Analysis dependencies belong in `workflow/envs/orthoevol.yaml`. The download
and BLAST rules use this environment through `conda:` and `script:` directives.
It supplies BLAST+ and the OrthoEvolution integration branch separately from the
launcher. Run with `--software-deployment-method conda` to enable deployment.

The existing `pyproject.toml` and `uv.lock` remain available for local Python
development with `uv sync --locked`. On the tested HPC login node, glibc 2.17
could not use the locked greenlet wheel, and compilation failed with the system
compiler. Use the Mamba setup below there. Do not use `.venv/bin/snakemake` or
`uv sync` to manage the Conda launcher environment.

The Conda specifications pin selected versions but are not complete dependency
locks. The launcher with the Slurm plugin and the analysis environment still
need installation and execution validation on Linux/glibc 2.17.

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

#### Prepare the Linux/HPC environment

These instructions assume Linux with Bash and an existing Miniforge/Mamba
installation. Run from the repository root on a node with network access where
your site's policy permits software installation. If either prerequisite is
missing, stop and follow your site's Miniforge setup instructions.

```bash
command -v mamba
command -v conda
export CONDA_CHANNEL_PRIORITY=strict
mamba env create --dry-run -f environment.yml
mamba env create -f environment.yml
conda activate orthoevol-snakemake
snakemake --version
```

If an environment with this name already exists from the earlier manual setup,
use `mamba env update -n orthoevol-snakemake -f environment.yml` instead of the
create command. Stop on a failed solve or installation.

Keep the checkout, launcher environment, and Snakemake's `.snakemake/conda/`
environments on storage visible to compute nodes. Activate the launcher in each
batch job and run from the repository root. Create rule environments before
submission; their installation may require network access. BLAST databases and
taxonomy data require separate preparation.

#### Configure workflow

Configure the workflow by editing `config/config.yaml`.

#### Validate the Linux setup

After activating the launcher, inspect the workflow and its planned jobs:

```bash
snakemake --lint
snakemake --dry-run --cores 1
snakemake download_blastdb --dry-run --cores 1
```

Lint findings describe remaining workflow work. A successful dry run checks job
planning, not execution correctness. The BLAST rule does not yet declare its
database dependency, and its output contract still needs end-to-end validation.

Prepare the analysis environment without executing BLAST or database downloads:

```bash
export CONDA_CHANNEL_PRIORITY=strict
snakemake --cores 1 --software-deployment-method conda --conda-create-envs-only
```

This downloads software and installs the rule environment. It does not retrieve
reference databases. Stop and report the solver or pip error if installation
fails. Successful launcher installation does not guarantee that the configured
OrthoEvolution dependencies support this Linux system.

The rule environment installs NumPy, SciPy, pandas, Matplotlib, Biopython, and
other compiled dependencies through Conda before pip installs the configured
OrthoEvolution revision. Their constraints allow the solver to select compatible
builds for the host; this specification is not a complete dependency lock.
Strict channel priority applies to this shell and its child processes. Repeat
the export in any batch job that creates environments.

If an earlier attempt failed while pip built NumPy from source, first obtain
the revised `workflow/envs/orthoevol.yaml`, then rerun the environment-creation
command above. Snakemake uses the changed environment definition to select a
new environment directory. There is no need to delete all of `.snakemake/`.
If creation fails again, report the first failing package and its build or
solver error. The revised dependency set still requires validation on Linux
with glibc 2.17.

#### Download the BLAST database in a batch job

After creating the rule environment, submit from the repository root. Set your
email in `config/config.yaml` first. This downloads and extracts the full
RefSeq RNA database, including taxonomy files, into `resources/blast/refseq_rna/`.
Confirm sufficient storage and network access before submission. Do not submit
a second download while another process is using that output directory.

Replace `YOUR_PARTITION` and `HH:MM:SS` below with an eligible Cheaha partition
and a walltime based on the download size, observed transfer rate, and extraction
time. The workflow's current 60-minute resource value is provisional, not a
measured estimate for the full download.

```bash
sbatch --partition=YOUR_PARTITION --time=HH:MM:SS scripts/download_blastdb.sbatch
```

Slurm returns a job ID and runs the job independently of your terminal session.
The script loads `miniforge/conda`, activates the launcher environment, and
runs Snakemake locally within one Slurm allocation, without submitting child
jobs. One CPU matches the current single download worker. The 2 GB memory
request is provisional, allowing 1 GB for the rule plus workflow overhead.

Monitor the job with `squeue -u "$USER"`. Scheduler output goes to
`download-blastdb-JOB_ID.log` in the repository root; package output goes to
`logs/download_blastdb.log`. After completion, replace `JOB_ID` below and inspect
the exit status, elapsed time, and memory use:

```bash
seff JOB_ID
sacct -j JOB_ID --format=JobID,State,ExitCode,Elapsed,AllocCPUS,MaxRSS
```

Use successful runs to refine memory and walltime requests. Diagnose failed
transfers separately from resource sizing. Download completion does not yet
connect the database to the BLAST rule. See [Cheaha's batch submission guidance](https://docs.rc.uab.edu/cheaha/slurm/submitting_jobs/).

#### Execute after integration validation

Once database dependencies and expected outputs have been validated on small
representative data, execute in a compute allocation:

```bash
snakemake --cores 1 --software-deployment-method conda
```

For scheduler submission, supply your configured site profile with `--profile`.
Installing the Slurm plugin alone does not configure cluster execution. Do not
launch production runs until representative integration validation passes.


### Test the OrthoEvolution integration branch

Push the package fixes to GitHub's `snakemake-fixes` branch before creating the
rule environment. The Conda YAML installs that branch directly. For local uv
users, `uv lock --upgrade-package OrthoEvol` followed by `uv sync --locked`
refreshes the branch revision after it is pushed. Until then, the lockfile
records the older GitHub branch head, which lacks the new taxonomy API.

Check `test_blast_branch/data/test_blast_branch_MAF.csv` and the timing CSV.
A missing mouse hit is a valid result; verify the human reference accession is
preserved. The Excel report is optional. Repeat the same command and confirm
Snakemake reports nothing to do. Use a new project name if inputs, database, or
search settings change, because package XML cache invalidation remains pending.

Snakemake hashes environment definitions, not the current GitHub branch head.
Later pushes do not refresh an already-created Conda environment. Before each
subsequent branch test, replace `@snakemake-fixes` in the rule YAML with the exact
pushed commit SHA. Pin the validated SHA in both dependency specifications when
branch testing is complete.
