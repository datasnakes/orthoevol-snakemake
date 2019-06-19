rule blastn:
    input:
        csvfile=""
    output:
        outfile="{}.zip".format(archive_path)
    script:
        ""