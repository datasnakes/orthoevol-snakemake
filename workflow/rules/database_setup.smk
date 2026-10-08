import os
import fnmatch
from subprocess import call, CalledProcessError
import contextlib
import sys
import re

from OrthoEvol.Tools.ftp import NcbiFTPClient
from OrthoEvol.Manager.database_management import BaseDatabaseManagement

bdm = BaseDatabaseManagement(email=config['email'], driver=config['driver'],
                             project=config['project'], project_path=os.getcwd())
                             

REFSEQRNA_DBS = ["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", 
                "11", "12", "13", "14", "15"]

REFSEQRELEASE_DBS = list(range(1, 261))

# Raise an error if you're not on linux. Windows generally doesn't have wget.
if 'linux' not in str(sys.platform):
    msg = 'This interface is not intended for use on your platform.'
    raise NotImplementedError(msg)


def write_to_file(hostname, dbname, dbpath, filenames):
    # Create a for loop that writes the list/text file of files wanted
    with open('downloadlist.txt', 'w') as downloads:
        for filename in filenames:
            # Get only those files.
            if fnmatch.fnmatch(filename, dbname + '*'):
                refseq_file = os.path.join(filename)
                # Write the url of each refseq_rna db file to a text file.
                downloads.writelines(hostname + dbpath + refseq_file + '\n')
            # use elif here to get the taxdb.tar.gz file.
            elif fnmatch.fnmatch(filename, 'taxdb*'):
                taxdb_file = os.path.join(filename)
                downloads.writelines(hostname + dbpath + taxdb_file + '\n')


def download_blastdb(email, dbname, num_procs=8):
    ncbiftp = NcbiFTPClient(email=email)
    log = ncbiftp.ncbiftp_log

    # This is a list of the file names in the current directory
    dbpath = ncbiftp.blastdbv5_path
    filenames = ncbiftp.listfiles(dbpath)
    
    download_path = "{}/databases/NCBI/blast/db/v5/".format(config['project'])
    os.chdir(download_path)
    
    with open('downloadlist.txt', 'w') as downloads:
        for filename in filenames:
            # Get only those files.
            if fnmatch.fnmatch(filename, dbname + '*'):
                refseq_file = os.path.join(filename)
                # Write the url of each refseq_rna db file to a text file.
                downloads.writelines(ncbiftp.ftp.host + dbpath + refseq_file + '\n')
            # use elif here to get the taxdb.tar.gz file.
            elif fnmatch.fnmatch(filename, 'taxdb*'):
                taxdb_file = os.path.join(filename)
                downloads.writelines(ncbiftp.ftp.host + dbpath + taxdb_file + '\n')
    log.info(num_procs)
    # Download the list of files using 'wget' on linux/unix
    with contextlib.suppress(os.error):
        cmd = 'cat downloadlist.txt | xargs -n 1 -P {} wget'.format(num_procs)
        status = call([cmd], shell=True)
        if status == 0:
            log.info("The %s blastdb files have been downloaded." % dbname)
        else:
            log.error(CalledProcessError)
            ncbiftp.close_connection()

    ncbiftp.close_connection()
    os.remove('downloadlist.txt')


def download_refseqrelease(email, collection_subset, seqtype, seqformat, num_procs=8):
    ncbiftp = NcbiFTPClient(email=email)
    log = ncbiftp.ncbiftp_log

    # This is a list of the file names in the current directory
    dbpath = ncbiftp.refseqrelease_path
    filenames = ncbiftp.listfiles(dbpath)

    pattern = re.compile('^' + collection_subset +
                         '[.](.*?)[.]' + seqtype + '[.]' + seqformat + '[.]gz$')
    
    download_path = "{}/databases/NCBI/refseq/release/{}".format(config['project'], collection_subset)
                         
    os.chdir(download_path)

    with open('downloadlist.txt', 'w') as downloads:
        for filename in filenames:
            # Get only those files.
            if re.match(pattern, filename):
                refseqrelease_file = os.path.join(filename)
                # Write the url of each refseq_rna db file to a text file.
                downloads.writelines(ncbiftp.ftp.host + dbpath + refseqrelease_file + '\n')
    # Download the list of files using 'wget' on linux/unix
    with contextlib.suppress(os.error):
        cmd = 'cat downloadlist.txt | xargs -n 1 -P {} wget'.format(num_procs)
        status = call([cmd], shell=True)
        if status == 0:
            log.info("The %s %s refseq release files have been downloaded." % (collection_subset, seqtype))
        else:
            log.error(CalledProcessError)
            ncbiftp.close_connection()

    ncbiftp.close_connection()
    os.remove('downloadlist.txt')
                             
rule download_blastdb:
    message:
        "Downloading preformatted blast database."
    input:
        config['accessions_file']
    output:
        expand("{project}/databases/NCBI/blast/db/v5/{dbname}_v5.{num}.tar.gz", 
               project=config['project'], dbname=config['database_name'], num=REFSEQRNA_DBS)
    run:
        download_blastdb(email=config['email'], dbname=config['database_name'],
                         num_procs=config['download_threads'])

rule download_refseqrelease:
    message:
        "Downloading refseq release files."
    input:
        config['accessions_file']
    output:
        expand("{project}/databases/NCBI/refseq/release/{subset}/{subset}.{num}.{seqtype}.{seqfmt}.gz", 
               project=config['project'], subset=config['collection_subset'],
               num=REFSEQRELEASE_DBS, seqtype=config['seqtype'], seqfmt=config['seqformat'])
    run:
        download_refseqrelease(email=config['email'], collection_subset=config['collection_subset'], 
        seqtype=config['seqtype'], seqformat=config['seqformat'], num_procs=config['download_threads'])