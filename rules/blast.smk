## Run OrthoBlastN ##
from OrthoEvol.Orthologs.Blast import OrthoBlastN

ACC = config['accessions_file']

NAME, EXT = ACC.split('.')

rule blastn:
    message:
        "Running blastn."
    input:
        acc=ACC
    output:
        expand("{project}/data/{project}_TIME.csv", project=config['project']),
        expand("{project}/index/" + ACC, project=config['project']),
        expand("{project}/index/" + NAME + ".sqlite", project=config['project']),
        expand("{project}/data/{project}_MAF.csv", project=config['project']),
        expand("{project}/data/{project}_postblastanalysis.xlsx", project=config['project'])
    run:
        blastn = OrthoBlastN(project=config['project'], method=config['method'],
                            save_data=config['save_data'], acc_file=input.acc,
                            copy_from_package=config['copy_from_package'])
        blastn.run()
