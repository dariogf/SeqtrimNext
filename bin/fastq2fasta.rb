#!/usr/bin/env ruby

require 'scbi_fastq'


if ARGV.count < 2
  puts "#{$0} FASTQ OUTPUT_NAME"
  exit
end


  
fastq = ARGV.shift
output_name = ARGV.shift


fasta = File.open(output_name+'.fasta','w')
qual = File.open(output_name+'.fasta.qual','w')

fqr=FastqFile.new(fastq)

fqr.each do |seq_name,seq_fasta,seq_qual,comments|

  fasta.puts ">#{seq_name} #{comments}"
  fasta.puts seq_fasta
  
  qual.puts ">#{seq_name} #{comments}"
  qual.puts seq_qual.join(' ')
  
end

fasta.close
qual.close
fqr.close

