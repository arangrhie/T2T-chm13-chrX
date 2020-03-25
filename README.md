# T2T-chm13-chrX

Generate single copy k-mer sites in a given assembly, as described in the [Miga et al. 2019 T2T chrX paper](https://www.biorxiv.org/content/10.1101/735928v3).

These locus were used for marker assisted mapping to avoid mapping biases due to assembly errors.
The script provided here generates marker sites in the assembly where the k-mer is unique (found only once) in the assembly and is coming from the single copy peak from the Illumina read set (collected from barcode trimmed 10X Genomics reads).

1. Download the CHM13 single copy k-mer meryl database from [here](https://s3.amazonaws.com/nanopore-human-wgs/chm13/10x/meryl/CHM13.10X.k21.gt5.lt58.meryl.tar).
```
# Untar
tar xvf CHM13.10X.k21.gt5.lt58.meryl.tar

# Give a more meaningful name
ln -s CHM13.10X.k21.gt5.lt58.meryl 10X_single.meryl
```

2. Get the [meryl v1.0](https://github.com/marbl/meryl/releases/tag/v1.0)

3. Run `collect_single_copy_kmers.sh`, which does

1) Collect unique k-mers in the assembly
```
meryl equal-to 1 k=21 [ count memory=12 asm.fasta output asm.meryl ] output asm_1.meryl
```

2) Intersect asm_1.meryl with single copy k-mers from the read set
```
meryl intersect 10X_single.meryl asm_1.meryl output markers.meryl
```

3) Lookup and dump the positions
```
# Run this for asm.fasta or on each chromosome ($chr) to speed up
meryl-lookup -dump -memory 12 -sequence $chr.fasta -mers markers.meryl | awk -F "\t" '$(NF-4)=="T" {print $1"\t"$(NF-5)"\t"$(NF-5)+21"\t"($(NF-2)+$NF}' > ${chr}_markers.bed
```

4. Optionally, generate marker density track with [IGVtools](http://software.broadinstitute.org/software/igv/download)
```
cat *_markers.bed > markers.bed
igvtools count markers.bed markers.tdf asm.fasta.fai
```
