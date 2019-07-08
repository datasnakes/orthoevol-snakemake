# orthoevol-snakemake

A snakemake workflow for the [OrthoEvol](https://github.com/datasnakes/OrthoEvolution) python package.

## Authors

* [Shaurita Hutchins](https://github.com/sdhutchins)
* [Rob Gilmore](https://github.com/grabear)

## Usage

### Simple

#### Install workflow

Clone the git repository and change to directory.

#### Configure workflow

Configure the workflow according to your needs via editing the file `config.yaml`.

#### Execute workflow

##### Test your configuration by performing a dry-run via

```console
[username@hostname]$ snakemake --use-conda -n
```

##### Execute the workflow locally via

```console
[username@hostname]$ snakemake --use-conda --cores $N
```

##### Run a specific rule

```console
[username@hostname]$ snakemake blastn --use-conda --cores $N
```

# Investigate results

