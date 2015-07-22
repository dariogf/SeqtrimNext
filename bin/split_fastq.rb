#!/usr/bin/env ruby

require 'scbi_fastq'


if ARGV.count < 3
  puts "#{$0} FASTQ OUTPUT_NAME SPLIT_BY [-gz]"
  exit
end

  
fastq = ARGV.shift
output_name = ARGV.shift
split_by = ARGV.shift.to_i

gz_arg=ARGV.shift
gz=false

if !gz_arg.nil? and gz_arg.index('-gz')
	gz='.gz'
end


file_index=1
out=FastqFile.new("#{output_name}#{file_index}.fastq#{gz}","w#{gz}")

fqr=FastqFile.new(fastq)

count = 0

fqr.each do |seq_name,seq_fasta,seq_qual,comments|
  
  out.write_seq(seq_name,seq_fasta,seq_qual,comments)

  count +=1

  if (count % split_by) == 0 
      
    file_index +=1
    out.close
    out=FastqFile.new("#{output_name}#{file_index}.fastq#{gz}","w#{gz}")

  end
end

out.close
fqr.close

