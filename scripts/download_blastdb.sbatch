#!/bin/bash
#SBATCH --job-name=orthoevol-download
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --output=logs/download-blastdb-%j.log

set -euo pipefail

# One CPU matches the configured single download worker; no array is needed.
# Memory is provisional: 1 GB for the rule plus room for the workflow process.
# Supply partition and walltime at submission based on transfer size and speed.
cd "${SLURM_SUBMIT_DIR:?Submit from the repository root}"

export PYTHONNOUSERSITE=1
export CONDA_CHANNEL_PRIORITY=strict

module load miniforge/conda
eval "$(conda shell.bash hook)"
conda activate orthoevol-snakemake

command -v snakemake
snakemake download_blastdb \
    --executor local \
    --cores "${SLURM_CPUS_PER_TASK}" \
    --software-deployment-method conda
