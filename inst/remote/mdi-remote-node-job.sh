#!/bin/bash

#SBATCH --job-name=mdi_web_server
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --partition=standard
#SBATCH --output=/home/%u/%x.log

# get input variables
export SHINY_PORT=$1

# run web server
Rscript mdi-remote-node.R
