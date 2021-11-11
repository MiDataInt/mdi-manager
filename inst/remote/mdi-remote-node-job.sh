#!/bin/bash

#SBATCH --job-name=mdi_web_server
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --partition=standard
#SBATCH --output=/home/%u/%x.log

# run web server
export MDI_REMOTE_MODE=node
Rscript $MDI_DIR/remote/mdi-remote.R
