#!/usr/bin/env nextflow

nextflow.enable.dsl=2


process fastp_se {

    cpus 4
    memory 6.GB
    publishDir params.out, mode: 'copy', overwrite: true

    input:
    file(fastq) 
 
    output:
    file "*_fastqc.{json,html}" 
    """
    fastp -i ${fastq} -j ${fastq.simpleName}.json -h ${fastq.simpleName}.html
    """
}

process fastp_pe {

    cpus 4
    memory 6.GB
    publishDir params.out, mode: 'copy', overwrite: true

    input:
    tuple val(name), file(fastq) 

    output:
    file "*_fastqc.{json,html}"
    """
    fastp -i ${fastq[0]} ${fastq[1]} -j ${name}.json -h ${name}.html
    """
}


process multiqc {
    cpus 2
    memory 2.GB
    publishDir params.out, mode: 'copy', overwrite: true

    input:
    file(reports)

    output:
    file "multiqc_report.html"

    """
    multiqc $reports
    """
}

/*workflow fastqc_multiqc_pipeline {
    take: fastq_file
    main:
        fastq_file = Channel.fromPath(params.in, type: 'file')
        fastqc(fastq_file)
        multiqc(fastqc.out.collect())
    emit:
        fastqc.out 
}*/

workflow {
    if(params.paired) {
        fastq_file = Channel.fromFilePair(params.in, type: 'file')
        fastp_pe(fastq_file)
        multiqc(fastqc.out.collect())
    } else
    {
        fastq_file = Channel.fromPath(params.in, type: 'file')
        fastp_se(fastq_file)
        multiqc(fastqc.out.collect())
    }
}
