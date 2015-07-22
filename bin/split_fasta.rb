#!/usr/bin/env ruby

require 'scbi_fasta'


if ARGV.count < 3
  puts "#{$0} FASTA_FILE OUTPUT_NAME SEQS_PER_FILE_COUNT"
  exit
end



fastq = ARGV.shift
output_name = ARGV.shift
split_by = ARGV.shift.to_i


file_index=1
out=File.new("#{output_name}#{file_index}.fasta",'w')
fqr=FastaQualFile.new(fastq)

count = 0

fqr.each do |seq_name,seq_fasta,comments|

  if (count >= split_by)
    count=0

    file_index +=1
    out.close
    out=File.new("#{output_name}#{file_index}.fasta",'w')
  end

  out.puts(">#{seq_name} #{comments}")
  out.puts(seq_fasta)

  count +=1

end

out.close if out
fqr.close