rule install_cellranger_atac:
  output: "cellranger-atac-2.0.0/cellranger-atac"
  message: "Installing Cellranger-atac v2"
  threads: 1
  shell:
    """
    curl -o cellranger-atac-2.0.0.tar.gz "https://cf.10xgenomics.com/releases/cell-atac/cellranger-atac-2.0.0.tar.gz?Expires=1622882840&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cHM6Ly9jZi4xMHhnZW5vbWljcy5jb20vcmVsZWFzZXMvY2VsbC1hdGFjL2NlbGxyYW5nZXItYXRhYy0yLjAuMC50YXIuZ3oiLCJDb25kaXRpb24iOnsiRGF0ZUxlc3NUaGFuIjp7IkFXUzpFcG9jaFRpbWUiOjE2MjI4ODI4NDB9fX1dfQ__&Signature=L3oAHwn6B~K~jZfX7W13lmsq3whfTkLdgO9Dalw~HdRqotrDPlUWBT6I2r4RWed7kBdoOtGoEowTxb~ek3oljyoXslyDyr9lTXRNY9iiu-cNYGrpwTXo3QEVnDt60FBjfV4OlqkH7rZGP~GZZdSYaccWo13U9tQ4IL0fR1A6nsQBQeBnTBGwJl6T6jIv66LqiMwVejMi6i~UjZ--s7BPLbIl5Kvs2MndrnWrJdFfztF1qYV-pMGAm6PEOMOwWtTd~~eA3XIc4YTh2Ab60OZW4PsarSLGQcj7bsW3Lhtf6zouqGRZ6ELM~9QZNgQyNLGw2nMMshEcOctLwE8BWZfNTw__&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA"
    tar -xzvf cellranger-atac-2.0.0.tar.gz
    rm cellranger-atac-2.0.0.tar.gz
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
    output: touch("data/{dset}/download.done")
    message: "Download datasets"
    threads: 1
    shell:
        """
        wget -i {input} -P data/{wildcards.dset}
        """
