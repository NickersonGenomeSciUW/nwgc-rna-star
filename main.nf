import groovy.json.JsonSlurper

include { STAR_MAP_MERGE_SORT } from './workflows/star_map_merge_sort.nf'
include { RNA_ANALYSIS } from './workflows/rna_analysis.nf'

workflow {

    // Versions channel
    ch_versions = Channel.empty()

    // Map/Merge using STAR
    println "Starting STAR_MAP_MERGE_SORT"
    STAR_MAP_MERGE_SORT()
    ch_versions = ch_versions.mix(STAR_MAP_MERGE_SORT.out.versions)

    read_count_ch = STAR_MAP_MERGE_SORT.out.readCountJson
                        .branch {readCount ->
                           pass: readCount[0] >= 3000
                                 return readCount
                           fail: readCount[0] < 3000
                                 return "Not enough reads to proceed " + readCount
                       }

    // If not enough reads, wwite early exit message to stdout
    read_count_ch.fail.view()

    // Enough reads, so proceed with RNA Analysis
    RNA_ANALYSIS(read_count_ch.pass, STAR_MAP_MERGE_SORT.out.transcriptome_bam)

    ch_versions.unique().collectFile(name: 'rna_star_software_versions.yaml', storeDir: "${params.sampleDirectory}")

}
