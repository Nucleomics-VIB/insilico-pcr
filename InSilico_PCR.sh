#!/bin/bash

# script: InSilico_PCR.sh

# required:
# conda with -f environment imported
# requires: bbmap, bioawk R (computing percentiles)
#
# Stephane Plaisance VIB-NC September-18-2019 v1.0
# version 1.1; 2019-10-04
# better handling of input file
# better handling of parallel jobs and threads
# version 1.1.1; 2019-10-28
# lower specs to better match low-end servers
# version 1.1.2; 2019-10-29
# add qin=${qual} to extraction command
# add include primer (t/f) as option in header
# reformat to page width
# version 1.1.3; 2022-02-08
# rename logs folder to allow consecutive runs
# add TMPDIR for bbmap and parallel
# version 1.1.4; 2026-10-21
# rename conda env to insilico-pcr (repo renamed from InSilico_PCR)
# version 1.1.5; 2026-10-22
# environment.yaml: conda-forge only, python >=3.10, certifi>=2026.10.19
# (eMudhra CA incident); recreate the conda env
#
# visit our Git: https://github.com/Nucleomics-VIB
#
version="1.1.5; 2026-10-22"
#
# required once: create a conda env to install the required apps
# conda env create -f environment.yaml
# adapt next line to point to the right conda.sh init script
# see conda activate script for details
source /etc/profile.d/conda.sh
conda activate insilico-pcr || \
  ( echo "# the conda environment 'insilico-pcr' was not found on this machine" ;
    echo "# please read the top part of the script!" \
    && exit 1 )

########## start user editable region ##############

# REM: the workflow can be restarted by deleting all log files after a given step

# speed-up
thr=8
pigt=2
mem="1g"

# extract reads corresponding to the 16S PCR
# Long ONT / PacBio amplicon V1-V9
forwardp="AGAGTTTGATCMTGGCTCAG"
forwardl="27F"
reversep="CGGTWACCTTGTTACGACTT"
reversel="1492Rw"

# typical V3-V4 amplicon
#forwardp="GACTCCTACGGGAGGCWGCAG"
#forwardl="337F"
#reversep="GACTACHVGGGTATCTAATCC"
#reversel="805R"

# hybrid amplicon V4-V9 a bit longer
#forwardp="GTGYCAGCMGCCGCGGTAA"
#forwardl="515FB"
#reversep="CGGTWACCTTGTTACGACTT"
#reversel="1492Rw"

# 4.4kb +/-full-length rRNA amplicon
#forwardp="AGRGTTYGATYMTGGCTCAG"
#forwardl="ncec_16S_8F_v7"
#reversep="CGACATCGAGGTGCCAAAC"
#reversel="ncec_23S_2490R_v7"

# be stringent to avoid noisy reads
cut=0.8

# split in 500k read bins and zip
lines=2000000

# quality phred scale of your data (for demo data it is 33)
qual=33

# expected amplicon size limits, set to 10 and 10000 by default
# adjust if you notice that the sequence extraction has unwanted tail(s)
readminlen=10
readmaxlen=100000

# whether to include the primer matches or to clip them (t/f)
primincl="t"

######## end of user editable region ############

# test arguments
if [ -z "$1" ]; then
    echo -e "\nUsage: $0 -d (for demo)
     or
       $0 <path to a local fastq.gz file>\n"
    exit 1
fi

if [[ "$1" == "-d" ]]; then
    # get mockcommunity data from the cloud
    # https://github.com/LomanLab/mockcommunity
    infile="Zymo-PromethION-EVEN-BB-SN.fq.gz"
    url="https://nanopore.s3.climb.ac.uk"
else
    if [ -f "${1}" ]; then
        infile=$1
    else
        echo "# input file not found!"
        exit 1
    fi
fi

# extract string for output names
name=$(basename ${infile%\.fq\.gz})

##################
# prepare folders

# working default to local folder
data="$(pwd)"

# split folder
split="split_data_${name}"
mkdir -p ${split}

# run logs
logs="run_logs_${name}"
mkdir -p ${logs}

# tmp output folder
tmpout="bbmap_out_${name}_${forwardl}_${reversel}"
mkdir -p ${tmpout}

# parallel folders
WORKDIR=$PWD
mkdir -p $PWD/tmp
export TMPDIR=$PWD/tmp

# keep track of all
runlog=${logs}/runlog.txt
exec &> >(tee -i ${runlog})

# also echo commands to log (verbose!)
# set -x

##################################
# download data for -d (once only)

if [[ "$1" == "-d" ]]; then
  if [[ ! -f "${infile}" ]]; then
    echo "# downloading ${infile} (may take some time!)"
    wget ${url}/${infile}
    touch ${logs}/done.gettingdata}
  else
    echo "# ${infile} was already downloaded from ${url}"
  fi
fi

###########################################
# split large file into chunks for parallel

if [[ ! -f ${logs}/done.splitting ]]; then
  echo "# splitting the data in multiple smaller files and compressing (may take some time!)"
  zcat ${infile} | \
    split -a 3 -d -l ${lines} --filter='pigz -p '${pigt}' \
    > $FILE.fq.gz' - ${split}/${name}_ && \
  touch  ${logs}/done.splitting
else
  echo "# splitting already done"
fi

#################################
# run in BBMap msa.sh in parallel
#################################

# compute job number & threads/job
jobs=$(ls ${split}|wc -l)
# limit to thr
if [[ "${jobs}" -gt "${thr}" ]]; then
	jobs=${thr}
fi
jobt=$((${thr}/${jobs}))

######################################################
# find forward primer using a fraction of the threads

if [[ ! -f ${logs}/done.searching.${name}_${forwardl} ]]; then
  echo "# searching for forward primer sequence: ${forwardp} in all files"
  find ${split} -type f -name "${name}_???.fq.gz" -printf '%P\n' |\
    sort -n |\
    parallel --workdir ${WORKDIR} --tmpdir ${TMPDIR} -j ${jobs} msa.sh -Xmx${mem} threads=${jobt} \
      qin=${qual} \
      in=${split}/{} \
      out=${tmpout}/forward_{}.sam \
      literal="${forwardp}" \
      rcomp=t cutoff=${cut} && \
    touch ${logs}/done.searching.${name}_${forwardl}
else
  echo "# forward search already done"
fi

######################################################
# find reverse primer using a fraction of the threads

if [[ ! -f ${logs}/done.searching.${name}_${reversel} ]]; then
  echo "# searching for reverse primer sequence: ${reversep} in all files"
  find ${split} -type f -name "${name}_???.fq.gz" -printf '%P\n' |\
    sort -n |\
    parallel --workdir ${WORKDIR} --tmpdir ${TMPDIR} -j ${jobs} msa.sh -Xmx${mem} threads=${jobt} \
      qin=${qual} \
      in=${split}/{} \
      out=${tmpout}/reverse_{}.sam \
      literal="${reversep}" \
      rcomp=t \
      cutoff=${cut} && \
  touch ${logs}/done.searching.${name}_${reversel}
else
  echo "# reverse search already done"
fi

##########################################
# extract regions with BBMap cutprimers.sh

if [[ ! -f ${logs}/done.cutprimer.${name}_${forwardl}_${reversel} ]]; then
  echo "# extracting template sequences between primer matches"
  find ${split} -type f -name "${name}_???.fq.gz" -printf '%P\n' |\
    sort -n |\
    parallel --workdir ${WORKDIR} --tmpdir ${TMPDIR} -j ${thr} cutprimers.sh -Xmx${mem} \
      qin=${qual} \
      in=${split}/{} \
      out=${tmpout}/{}_16s.fq \
      sam1=${tmpout}/forward_{}.sam \
      sam2=${tmpout}/reverse_{}.sam \
      include=${primincl} \
      fixjunk=t && \
  touch ${logs}/done.cutprimer.${name}_${forwardl}_${reversel}
fi

###########################################################
# merge results and keep only reads in amplicon size range

if [[ ! -f ${logs}/done.merging.${name}_${forwardl}_${reversel} ]]; then
  # clear existing results
  final="${name}_filtered_${forwardl}_${reversel}.fq.gz"
  cat /dev/null > ${final}
  echo "# filtering results at min:${readminlen} and max:${readmaxlen} and merging to ${final}"
  find ${tmpout} -type f -name "${name}_???.fq.gz_16s.fq" | \
    sort -n |\
    xargs cat |\
    bioawk -c fastx -v min="${readminlen}" -v max="${readmaxlen}" \
    '{if (length($seq)>=min && length($seq)<=max)
      print "@"$name" "$comment"\n"$seq"\n+\n"$qual}' |\
    bgzip >> ${final} && \
  touch ${logs}/done.merging.${name}_${forwardl}_${reversel}
else
  echo "# merging and filtering already done"
  echo "# force redo by deleting ${logs}/done.merging.${name}_${forwardl}_${reversel}"
fi

# return to normal
conda deactivate
