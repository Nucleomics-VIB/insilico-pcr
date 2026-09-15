[(Nucleomics-VIB)](https://github.com/Nucleomics-VIB)

InSilico PCR
==========

This Analysis aims at extracting genomic sequences mimicking 16S amplicon reads from a larger context long read set (gDNA reads or larger amplicons).

The motivation behind this analysis was to simulate 16S long amplicon sequencing on ONT platform using data obtained from the **https://github.com/LomanLab/mockcommunity** site as a large Promethion fastq archive but any other ONT or Pacbio fastq data can be used with this code <i>(please acknowledge [them](https://github.com/LomanLab/mockcommunity) when you would use this data too)</i>.

## Data Availability 

<il>(reproduced from https://github.com/LomanLab/mockcommunity/edit/master/README.md)</il>

|Name|Reads (M)|Yield (G)|FASTQ|Run Folder|Restarts|FAST5|
|:--|:--|:--|:--|:--|:--|:--|
|Zymo-PromethION-LOG-BB-SN|35.1|148|[fastq.gz](https://nanopore.s3.climb.ac.uk/Zymo-PromethION-LOG-BB-SN.fq.gz)|[64h run](https://nanopore.s3.climb.ac.uk/Zymo-PromethION-LOG-BB-SN_basecalls.tar.gz)|[restarts](https://nanopore.s3.climb.ac.uk/Zymo-PromethION-LOG-BB-SN-restarts_basecalls.tar.gz)|[download.sh](https://gist.github.com/SamStudio8/3ebbbd04dd8db557a3e8bdcedc875ee6), [restarts.tar](https://nanopore.s3.climb.ac.uk/Zymo-PromethION-LOG-BB-SN-restarts_signal.tar)|
|Zymo-PromethION-EVEN-BB-SN|36.5|146|[fastq.gz](https://nanopore.s3.climb.ac.uk/Zymo-PromethION-EVEN-BB-SN.fq.gz)|[64h run](https://nanopore.s3.climb.ac.uk/Zymo-PromethION-EVEN-BB-SN_basecalls.tar.gz)|[restarts](https://nanopore.s3.climb.ac.uk/Zymo-PromethION-EVEN-BB-SN-restarts_basecalls.tar.gz)|[download.sh](https://gist.github.com/SamStudio8/3ebbbd04dd8db557a3e8bdcedc875ee6), [restarts.tar](https://nanopore.s3.climb.ac.uk/Zymo-PromethION-EVEN-BB-SN-restarts_signal.tar)|
|Zymo-GridION-LOG-BB-SN|3.7|16|[fastq.gz](https://nanopore.s3.climb.ac.uk/Zymo-GridION-LOG-BB-SN.fq.gz)|[48h run](https://nanopore.s3.climb.ac.uk/Zymo-GridION-LOG-BB-SN_basecalled.tgz)|n/a|[signal.tar](https://nanopore.s3.climb.ac.uk/Zymo-GridION-LOG-BB-SN_signal.tar)|
|Zymo-GridION-EVEN-BB-SN|3.5|14|[fastq.gz](https://nanopore.s3.climb.ac.uk/Zymo-GridION-EVEN-BB-SN.fq.gz)|[48h run](https://nanopore.s3.climb.ac.uk/Zymo-GridION-EVEN-BB-SN_basecalled.tgz)|n/a|[signal.tar](https://nanopore.s3.climb.ac.uk/Zymo-GridION-EVEN-BB-SN_signal.tar)|

## Method

The method used to extract sequences between primers was developed by Brian Bushnell based on his [BBMap tools](https://jgi.doe.gov/data-and-tools/bbtools/) and is explained [here](https://www.biostars.org/p/216039/#216054).

The workflow is as follows:

* split the data in smaller fastq bins for speed-up using parallel
* search forward primer in all bins using BBMap msa.sh
* search reverse primer in all bins using BBMap msa.sh
* extract 'matching' regions using BBMAp cutprimers.sh 
* merge all results and keep only amplicons in a chosen size range (as set in the script)

## Usage

REM: Snakemake does not always install well with bioconda and can be removed from the file environment.yaml if you encounter issues. It is not used in the current version of this code anyway and was added here for forward compatibility.

* Install the required software using conca or manually based on the list provided in **environment.yaml**. 

* Set variables, names, and numeric limits in the top of the **InSilico_PCR.sh** script (adjust the number of threads to the available cores in your own machine)

* Run the script with 
  * demo data: **./InSilico_PCR.sh -d**
  * your own read file present in the current folder: **./InSilico_PCR.sh <file_name>.fq.gz**

## Results obtained with the demo data

* the results of a 16S In-Silico PCR experiment are presented in **[ZymoPromethion_even_Results](ZymoPromethion_even_Results.md)**.

* the results of using other databases for the **[MetONTIIME](https://github.com/MaestSi/MetONTIIME)** classification are reported **<a href="https://github.com/Nucleomics-VIB/insilico-pcr/raw/main/results/Metontiime_with_other_DBs.pdf" target="_blank">here</a>**.

## Future plans

This code should and will be changed to a **snakemake** pipeline in order to be more portable. The config.yaml file is the first step towards this transition.

<hr>

<h4>Please send comments and feedback to <a href="mailto:nucleomics.bioinformatics@vib.be">nucleomics.bioinformatics@vib.be</a></h4>

<hr>

![Creative Commons License](http://i.creativecommons.org/l/by-sa/3.0/88x31.png?raw=true)

This work is licensed under a [Creative Commons Attribution-ShareAlike 3.0 Unported License](http://creativecommons.org/licenses/by-sa/3.0/).
