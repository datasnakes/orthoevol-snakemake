# The main snakefile
configfile: "config.yml"


rule all:
  input:

include: "rules/setup.smk"
include: "rules/blast.smk"
