from OrthoEvol.Orthologs.Blast import OrthoBlastN


rule blastn:
    input:
        acc=config['accessions_file']
    log: 
        "blastn.log"
    output:
        path=config['project']
    run:
        blastn = OrthoBlastN(project=config['project'], method=config['method'],
                            save_data=config['save_data'], acc_file={input.acc},
                            copy_from_package=config['copy_from_package'])
        blastn.run()
