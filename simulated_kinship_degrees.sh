#!/usr/bin/env bash

###############################################################################
#           Aydin Loid Karatas
#           ---
#           University of Southern California
#           Department of Quantitative and Computational Biology
#           Mooney Lab
#           ---
#           simulated_kinship_degrees.sh
###############################################################################

#SBATCH --job-name=kinshipDegrees
#SBATCH -p qcb
#SBATCH -A jazlynmo_738
#SBATCH -N 1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=350G
#SBATCH --time=1-00:00:00
#SBATCH --output=/home1/karatas/logs/kinshipDegrees/%A.%x.out
#SBATCH --error=/home1/karatas/logs/kinshipDegrees/%A.%x.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=karatas@usc.edu


##### set up ##################################################################
set -euo pipefail

# submit from the project checkout; Slurm runs a spooled copy of this script.
: "${SLURM_SUBMIT_DIR:?ERROR: submit with sbatch from the project root}"
project_dir="${SLURM_SUBMIT_DIR}"
cd "${project_dir}"

module purge
ml rstats/4.5.1

##### simulation ##############################################################
# use the R defaults unless named CLI arguments are supplied to sbatch.
Rscript "${project_dir}/simulated_kinship_degrees.R" "$@"
