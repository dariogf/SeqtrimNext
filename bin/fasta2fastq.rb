#!/usr/bin/env ruby

require 'scbi_fasta'
require 'scbi_fastq'


if ARGV.count < 3
  puts "#{$0} FASTA QUAL OUTPUT_NAME"
  exit
end


  
fasta = ARGV.shift
qual = ARGV.shift
output_name = ARGV.shift
default_qual = nil

if !File.exists?(qual)
  fqr=FastaFile.new(fasta)
  puts "Quality file doesn't exists. Using default qual value = 40"
  default_qual = [40]
else
  fqr=FastaQualFile.new(fasta,qual)
end

output=FastqFile.new(output_name+'.fastq','w')

fqr.each do |seq_name,seq_fasta,seq_qual|
    if default_qual
      seq_qual =   default_qual * seq_fasta.length
    end
	  output.write_seq(seq_name,seq_fasta,seq_qual)
end

output.close
fqr.close

