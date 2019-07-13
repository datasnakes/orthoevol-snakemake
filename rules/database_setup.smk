import os
from OrthoEvol.Manager.database_management import BaseDatabaseManagement


bdm = BaseDatabaseManagement(email=config['email'], driver=config['driver'],
                             project=config['project'], project_path=os.getcwd())

REFSEQRNA_DBS = ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", 
                "11", "12", "13", "14", "15"]

rule download_blastdb:
    message:
        "Downloading preformatted blast database."
    input:
        config['accessions_file']
    output:
        expand("{project}/databases/NCBI/blast/db/v5/{dbname}_v5.{num}.tar.gz", 
               project=config['project'], dbname=config['database_name'], num=REFSEQRNA_DBS)
    run:
        bdm.download_blast_database(database_name=config['database_name'], 
                                    v5=config['use_v5_database'], set_blastdb=config['set_blastdb'])
