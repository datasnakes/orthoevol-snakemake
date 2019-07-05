from OrthoEvol.Orthologs.Blast import OrthoBlastN


rule blastn:
    message:
        "Running blastn."
    output:
        expand("{project}/data/{project}_building_time.csv", project=config['project'])
    run:
        print(input)
        blastn = OrthoBlastN(project=config['project'], method=config['method'],
                            save_data=config['save_data'], acc_file=config['accessions_file'],
                            copy_from_package=config['copy_from_package'])
        blastn.run()
