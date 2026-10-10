ACC = Path(config["accessions_file"])
PROJECT = config["project"]


rule blastn:
    message:
        "Running blastn."
    input:
        acc=str(ACC),
        database=blast_database_files
    output:
        timings=f"{PROJECT}/data/{PROJECT}_TIME.csv",
        input_accessions=f"{PROJECT}/index/{ACC.name}",
        accession_database=f"{PROJECT}/index/{ACC.stem}.sqlite",
        accessions=f"{PROJECT}/data/{PROJECT}_MAF.csv",
        report=f"{PROJECT}/data/{PROJECT}_postblastanalysis.xlsx"
    params:
        project=PROJECT,
        method=config["method"],
        save_data=config["save_data"],
        copy_from_package=config["copy_from_package"],
        database_directory=lambda wildcards, input: str(
            Path(input.database[0]).parent.resolve()
        )
    threads: 1
    resources:
        mem_mb=config["resources"]["blastn"]["mem_mb"],
        runtime=config["resources"]["blastn"]["runtime"]
    log:
        "logs/blastn.log"
    conda:
        "../envs/orthoevol.yaml"
    script:
        "../scripts/run_blast.py"
