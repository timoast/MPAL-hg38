samples = [
"scATAC_BMMC_D5T1",
"scATAC_BMMC_D6T1",
"scATAC_CD34_D7T1",
"scATAC_CD34_D8T1",
"scATAC_CD34_D9T1",
"scATAC_PBMC_D10T1",
"scATAC_PBMC_D11T1",
"scATAC_PBMC_D12T1",
"scATAC_PBMC_D12T2",
"scATAC_PBMC_D12T3"
]

rule all:
  input: expand("mapped/{dset}/fragments.tsv.gz", dset = samples)

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
    output: "data/{dset}.bam.1"
    message: "Download datasets"
    threads: 1
    shell:
        """
        while read line; do
          gsutil -u mpal-hg38 cp $line ./data/
        done < {input}
        """

rule unmap_bam:
  input:
    bam="data/{dset}.bam.1",
    program="code/bamtofastq"
  output: directory("fastq/{dset}")
  message: "Converting to FASTQ"
  threads: 8
  shell:
    """
    {input.program} --nthreads={threads} {input.bam} fastq/{wildcards.dset}/
    """

rule cellranger:
  input:
    fq="fastq/{dset}/",
    genome="refdata-cellranger-arc-GRCh38-2020-A-2.0.0/"
  output: "mapped/{dset}/fragments.tsv.gz"
  message: "Running cellranger-atac"
  threads: 12
  shell:
    """
    cellranger-atac count \
      --reference={input.genome} \
      --id={wildcards.dset} \
      --fastqs={input.fq} \
      --jobmode=./slurm.template
    mv {wildcards.dset}/outs/fragments.tsv.gz {output}
    """
