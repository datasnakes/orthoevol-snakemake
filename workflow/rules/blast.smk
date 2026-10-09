## Run OrthoBlastN ##
ACC = config['accessions_file']

NAME, EXT = ACC.split('.')

rule blastn:
    message:
        "Running blastn."
    input:
        acc=ACC,
        database=blast_database_files
    output:
        expand("{project}/data/{project}_TIME.csv", project=config['project']),
        expand("{project}/index/" + ACC, project=config['project']),
        expand("{project}/index/" + NAME + ".sqlite", project=config['project']),
        expand("{project}/data/{project}_MAF.csv", project=config['project']),
        expand("{project}/data/{project}_postblastanalysis.xlsx", project=config['project'])
    params:
        project=config['project'],
        method=config['method'],
        save_data=config['save_data'],
        copy_from_package=config['copy_from_package'],
        database_directory=lambda wildcards, input: str(
            Path(input.database[0]).parent.resolve()
        )
    threads: 1
    resources:
        mem_mb=config['resources']['blastn']['mem_mb'],
        runtime=config['resources']['blastn']['runtime']
    log:
        "logs/blastn.log"
    conda:
        "../envs/orthoevol.yaml"
    script:
        "../scripts/run_blast.py"
