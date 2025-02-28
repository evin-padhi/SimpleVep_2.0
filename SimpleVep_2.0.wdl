version 1.0

workflow Vep{
 input{
    File variant_file
    File? variant_file_index
    String input_format = "vcf"

    File reference_fasta
    File vep_cache_tarball

    String vep_assembly = "GRCh38"
    Int vep_version = 110
    
    Int mem_gb
    Int disk_gb 
    String vep_docker = "vanallenlab/g2c-vep:latest"
}
call RunVep {
    input:
      variant_file = variant_file,
      variant_file_index = variant_file_index,
      input_format = input_format,
      reference_fasta = reference_fasta,
      vep_cache_tarball = vep_cache_tarball,
      vep_assembly = vep_assembly,
      vep_version = vep_version,
      docker = vep_docker
  }
 output {
    File annotated_variants = RunVep.annotated_variants
  }
}


task RunVep {
    input {
        File variant_file
        File? variant_file_index
        String input_format
        String output_file_prefix
        File reference_fasta
        File vep_cache_tarball
        String vep_assembly
        Int vep_version = 110
        Float mem_gb 
        Int n_cpu = 4
        Int disk_gb
        String docker
    }

    String out_filename = output_file_prefix + ".vep.tsv"

    command <<<
    mkdir -p "vep_cache"
    tar -xzf ~{vep_cache_tarball} -C "vep_cache/"

    vep \
      --input_file ~{variant_file} \
      --format ~{input_format} \
      --output_file ~{out_filename} \
      --tab \
      --verbose \
      --force_overwrite \
      --species homo_sapiens \
      --assembly ~{vep_assembly} \
      --offline \
      --cache \
      --dir_cache "vep_cache/" \
      --cache_version ~{vep_version} \
      --minimal \
      --nearest gene \
      --distance 10000 \
      --numbers \
      --hgvs \
      --no_escape \
      --symbol \
      --canonical \
      --domains
    gzip -f ~{out_filename}
    >>>
    
    output {
        File annotated_variants = "~{out_filename}.gz"
    }

    runtime {
        docker: docker
        memory: "~{mem_gb} GB"
        cpu: n_cpu
        disks: "local-disk " +  disk_gb + "GB HDD"
        bootDiskSizeGb: 25
        preemptible: 3
    }
}
