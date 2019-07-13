# The main snakefile
configfile: "config.yml"


rule all:
  input:

include: "rules/database_setup.smk"
include: "rules/blast.smk"
