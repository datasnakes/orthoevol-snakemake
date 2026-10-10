import json

from snakemake.iocontainers import Wildcards


def blast_database_files(wildcards: Wildcards) -> list[str]:
    """Expose individual volumes after package-driven database discovery."""
    if config["database"]["mode"] == "existing":
        return [
            str(Path(config["database"]["directory"]) / name)
            for name in config["database"]["files"]
        ]
    manifest_path = Path(checkpoints.download_blastdb.get().output.manifest)
    database_directory = manifest_path.parent
    with manifest_path.open() as manifest_file:
        manifest = json.load(manifest_file)
    return [str(manifest_path)] + [
        str(database_directory / entry["name"]) for entry in manifest["files"]
    ]


checkpoint download_blastdb:
    input:
        support=workflow.source_path("../scripts/download_support.py")
    output:
        # Preserve archives and extraction markers when retrying an interrupted job.
        manifest="resources/blast/refseq_rna/workflow-manifest.json"
    params:
        email=config["email"],
        workers=config["database"]["download_workers"]
    threads: 1
    resources:
        mem_mb=config["resources"]["download_blastdb"]["mem_mb"],
        runtime=config["resources"]["download_blastdb"]["runtime"]
    log:
        "logs/download_blastdb.log"
    benchmark:
        "benchmarks/download_blastdb.tsv"
    conda:
        "../envs/orthoevol.yaml"
    script:
        "../scripts/download_blastdb.py"


rule download_refseqrelease:
    input:
        support=workflow.source_path("../scripts/download_support.py")
    output:
        release=directory("resources/refseq/{subset}/{seqtype}.{seqformat}")
    wildcard_constraints:
        subset="[a-z_]+",
        seqtype="rna|genomic|protein",
        seqformat="gbff|fna|faa|gpff"
    params:
        email=config["email"]
    threads: 1
    resources:
        mem_mb=config["resources"]["download_refseqrelease"]["mem_mb"],
        runtime=config["resources"]["download_refseqrelease"]["runtime"]
    log:
        "logs/refseq/{subset}.{seqtype}.{seqformat}.log"
    benchmark:
        "benchmarks/refseq/{subset}.{seqtype}.{seqformat}.tsv"
    conda:
        "../envs/orthoevol.yaml"
    script:
        "../scripts/download_refseqrelease.py"


rule refseq:
    input:
        expand(
            "resources/refseq/{subset}/{seqtype}.{seqformat}",
            subset=config["refseq"]["collection_subset"],
            seqtype=config["refseq"]["seqtype"],
            seqformat=config["refseq"]["seqformat"],
        )


rule prepare_taxonomy:
    output:
        database=config["taxonomy_db"],
        traversal=config["taxonomy_db"] + ".traverse.pkl"
    threads: 1
    resources:
        mem_mb=config["resources"]["prepare_taxonomy"]["mem_mb"],
        runtime=config["resources"]["prepare_taxonomy"]["runtime"]
    log:
        "logs/prepare_taxonomy.log"
    benchmark:
        "benchmarks/prepare_taxonomy.tsv"
    conda:
        "../envs/orthoevol.yaml"
    script:
        "../scripts/prepare_taxonomy.py"
