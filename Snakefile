samples = ["scATAC_BMMC_D6T1"]

rule all:
  input: expand("mapped/{dset}/outs/fragments.tsv.gz", dset = samples)

rule install_bamtofastq:
  output: "code/bamtofastq"
  message: "Installing bamtofastq"
  threads: 1
  shell:
    """
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      wget https://github.com/10XGenomics/bamtofastq/releases/download/v1.3.5/bamtofastq_linux -P code
      cd code
      mv bamtofastq_linux bamtofastq
      chmod +x bamtofastq
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      wget https://github.com/10XGenomics/bamtofastq/releases/download/v1.3.5/bamtofastq_macos -P code
      cd code
      mv bamtofastq_macos bamtofastq
      chmod +x bamtofastq
    else
      echo "Unsupported OS"
    fi
    """

rule reference_genome:
  output: directory("refdata-cellranger-arc-GRCh38-2020-A-2.0.0")
  message: "Downloading reference genome"
  threads: 1
  shell:
    """
    curl -O https://cf.10xgenomics.com/supp/cell-atac/refdata-cellranger-arc-GRCh38-2020-A-2.0.0.tar.gz
    tar -xzvf refdata-cellranger-arc-GRCh38-2020-A-2.0.0.tar.gz
    rm refdata-cellranger-arc-GRCh38-2020-A-2.0.0.tar.gz
    """

rule download:
    input: "datasets/{dset}.txt"
    output: "data/{dset}.bam"
    message: "Download datasets"
    threads: 1
    shell:
        """
        while read line; do
          aws s3 cp $line ./data/{dset}/
        done < {input}
        """

rule unmap_bam:
  input:
    bam="data/{dset}.bam",
    program="code/bamtofastq"
  output: "data/{dset}/{dset}_1.fastq"
  message: "Converting to FASTQ"
  threads: 12
  shell:
    """
    {input.program} --nthreads={threads} {input.bam} data/{wildcards.dset}/
    """

rule cellranger:
  input:
    fq="data/{dset}/{dset}_1.fastq",
    genome=directory("refdata-cellranger-arc-GRCh38-2020-A-2.0.0")
  output: "mapped/{dset}/outs/fragments.tsv.gz"
  message: "Running cellranger-atac"
  threads: 12
  shell:
    """
    cellranger-atac count \
      --reference={input.genome} \
      --id={wildcards.dset} \
      --fastqs={inout.fq} \
      --localcores={threads} \
      --localmem=64
    """
