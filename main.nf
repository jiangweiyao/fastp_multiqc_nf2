#!/usr/bin/env nextflow

nextflow.enable.dsl=2


process fastp_se {
    cpus 4
    memory 60.GB
    publishDir params.output_dir, mode: 'copy', overwrite: true

    input:
    file(fastq) 
 
    output:
    file "*_fastp.{json,html}" 
    """
    zcat ${fastq} | fastp --stdin -j ${fastq.simpleName}_fastp.json -h ${fastq.simpleName}_fastp.html --adapter_sequence=${params.adapterF} -Q -L
    """
}

process fastp_pe {
    cpus 6
    memory 60.GB
    publishDir params.output_dir, mode: 'copy', overwrite: true

    input:
    tuple val(name), file(fastq) 

    output:
    file "*_fastp.{json,html}"
    """
    seqtk mergepe ${fastq[0]} ${fastq[1]} | fastp -w 5 --stdin --interleaved_in -j ${name}_fastp.json -h ${name}_fastp.html --adapter_sequence=${params.adapterF} --adapter_sequence_r2=${params.adapterR} -Q -L
    """
}


process multiqc {
    cpus 2
    memory 2.GB
    publishDir params.output_dir, mode: 'copy', overwrite: true

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
        fastq_file = Channel.fromPath(params.input_fastq, type: 'file')
        fastqc(fastq_file)
        multiqc(fastqc.out.collect())
    emit:
        fastqc.out 
}*/

workflow {
    if(params.paired) {
        fastq_file = Channel.fromFilePairs(params.input_fastq, type: 'file')
        fastp_pe(fastq_file)
        multiqc(fastp_pe.out.collect())
    } else
    {
        fastq_file = Channel.fromPath(params.input_fastq, type: 'file')
        fastp_se(fastq_file)
        multiqc(fastp_se.out.collect())
    }
}
