#!/bin/bash

if [[ -z $1 ]] || [[ -z $2 ]]; then
    echo "Usage: ./collect_single_copy_kmers.sh <read_single.meryl> </full/path/to/asm.fasta> [chr]"
    echo "This script links asm.fasta and collects single copy kmers."
    echo -e "\t<read_single.meryl>: Single copy k-mer meryl db obtained from Illumina WGS reads"
    echo -e "\t<asm.fasta>: Target of interest assembly"
    echo -e "\t[chr]: contig/scaffold sequence ID to prepare the kmer db. Will run on full asm if not provided."
    exit -1
fi

read_single=$1
asm=$2
chr=$3

if [ ! -e asm.fasta ]; then
    ln -s $asm asm.fasta
fi

if [ -e $asm.fai ]; then
    ln -s $asm.fai asm.fasta.fai
elif [[ -e asm.fasta.fai ]]; then 
    echo "Generate .fai for asm.fasta"
    samtools faidx asm.fasta
fi

if [[ ! -z $chr ]]; then
    # Make sure $chr is found in asm.fasta.fai
    grep $chr asm.fasta.fai
fi
echo

if [ -z "$(ls -A markers.meryl 2> /dev/null )" ]; then
    echo "Collect unique k-mers in the asm"
    meryl equal-to 1 k=21 [ count memory=12 asm.fasta output asm.meryl ] output asm_1.meryl

    echo "Intersect with $read_single"
    meryl intersect $read_single asm_1.meryl output markers.meryl
fi

# No $chr provided. Run it for the full asm. Will take some hours...
if [[ -z $chr ]]; then
    echo "Lookup and dump positions on the full assembly"
    meryl-lookup -dump -memory 12 -sequence asm.fasta -mers markers.meryl | \
        awk -F "\t" '$(NF-4)=="T" {print $1"\t"$(NF-5)"\t"($(NF-5)+21)"\t"($(NF-2)+$NF)}' \
        > markers.bed
    echo -e "igvtools count markers.bed markers.tdf asm.fasta.fai\t# will generate IGV track with the marker density."
    exit 0
fi

# $chr detected. Run in parallel
if [ ! -s $chr.fasta ]; then
    echo "Pull out $chr"
    samtools faidx -r $chr asm.fasta > $chr.fasta
fi
echo

if [ ! -s ${chr}_markers.bed ]; then
    echo "Lookup and dump positions for $chr"
    meryl-lookup -dump -memory 12 -sequence $chr.fasta -mers markers.meryl | \
        awk -F "\t" '$(NF-4)=="T" {print $1"\t"$(NF-5)"\t"$(NF-5)+21"\t"($(NF-2)+$NF)}' \
        > ${chr}_markers.bed
fi

echo

echo "#########################"
echo -e "cat *_markers.bed > markers.bed\t# once collected for all chrs, merge the per-chr bed files."
echo -e "igvtools count markers.bed markers.tdf asm.fasta.fai\t# will generate IGV track with the marker density."

