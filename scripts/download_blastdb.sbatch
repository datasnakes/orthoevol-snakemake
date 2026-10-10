#!/bin/bash
#SBATCH --job-name=orthoevol-test
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --output=logs/test-blast-%j.log

set -euo pipefail

# One CPU matches the serial BLAST test; this single query needs no array.
# Memory is provisional: 1 GB for the rule plus room for the workflow process.
# Supply a CPU partition and provisional test walltime at submission.
cd "${SLURM_SUBMIT_DIR:?Submit from the repository root}"

export PYTHONNOUSERSITE=1
export CONDA_CHANNEL_PRIORITY=strict

module load miniforge/conda
eval "$(conda shell.bash hook)"
conda activate orthoevol-snakemake

command -v snakemake

snakemake all \
    --executor local \
    --cores "${SLURM_CPUS_PER_TASK}" \
    --software-deployment-method conda \
    --rerun-incomplete \
    --config project=test_blast_branch accessions_file=test_blast.csv
