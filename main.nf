// Suheel Yousuf Wani
nextflow {
    // Resources for the pipeline
    resources {
        
        cpus 16
        memory '16GB'
        time '12h'
    }

    // Input data channel
    input:
    path 'input_data/*.fastq' into rawReads

    // Output directory
    output:
    path 'output/'

    // Preprocessing
    process preprocessReads {
        
        input:
        path rawRead

        output:
        path "${name}_preprocessed.fastq" into preprocessedReads

        script:
        """
        # Add preprocessing commands here (e.g., quality trimming, adapter removal)
        cp ${rawRead} ${name}_preprocessed.fastq
        """
    }

    // Define the process to map reads to a reference genome
    process mapReads {
        // Customize this process based on the tool you want to use for read mapping
        input:
        path preprocessedRead

        output:
        path "${name}.bam" into mappedReads

        script:
        """
        
        bwa mem reference_genome.fasta ${preprocessedRead} > ${name}.sam
        samtools view -S -b ${name}.sam > ${name}.bam
        """
    }

    // Calling variants
    process callVariants {
        
        input:
        path mappedRead

        output:
        path "${name}.vcf" into variantCalls

        script:
        """
        
        samtools mpileup -uf reference_genome.fasta ${mappedRead} | bcftools call -c > ${name}.vcf
        """
    }

    // Consensus sequence
    process generateConsensus {
        
        input:
        path variantCall

        output:
        path "${name}_consensus.fasta" into consensusSequences

        script:
        """
        
        bcftools consensus -f reference_genome.fasta ${variantCall} > ${name}_consensus.fasta
        """
    }
}

// pipeline WF
workflow {
    // Preprocess
    preprocessReads(rawReads)

    // Mapping
    mapReads(preprocessedReads)

    // Call variants
    callVariants(mappedReads)

    // Consensus sequences
    generateConsensus(variantCalls)
}
