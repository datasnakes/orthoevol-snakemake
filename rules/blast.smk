from OrthoEvol.Orthologs.Blast import OrthoBlastN


rule blastn:
    message:
        "Running blastn."
    input:
        acc=config['accessions_file']
    output:
        expand("{project}/data/{project}_building_time.csv", project=config['project'])
    run:
        blastn = OrthoBlastN(project=config['project'], method=config['method'],
                            save_data=config['save_data'], acc_file={input.acc},
                            copy_from_package=config['copy_from_package'])
        blastn.run()
