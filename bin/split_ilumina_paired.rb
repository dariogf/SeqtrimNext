#!/usr/bin/env ruby

# Splits a FastQ file with ilumina paired data into two separate files.

require 'scbi_fastq'

VERBOSE=false

if !(ARGV.count==2 or ARGV.count==4)
  puts "Usage: #{$0} paired.fastq output_name [pared1_tag paired2_tag]"
  exit
end

p1_path=ARGV[0]
output_base_name=ARGV[1]

paired1_tag='/1'
paired2_tag='/2'

if (ARGV.count==4)
  paired1_tag=ARGV[2]
  paired2_tag=ARGV[3]
end

PAIRED1_TAG_RE=/#{Regexp.quote(paired1_tag)}$/
PAIRED2_TAG_RE=/#{Regexp.quote(paired2_tag)}$/


if !File.exists?(p1_path)
  puts "File #{p1_path} doesn't exists"
  exit
end

paired1_out = FastqFile.new(output_base_name+'_paired1.fastq','w',:sanger, true)
paired2_out = FastqFile.new(output_base_name+'_paired2.fastq','w',:sanger, true)


f_file = FastqFile.new(p1_path,'r',:sanger, true)

f_file.each do |n,f,q,c|
  
  if n=~ PAIRED1_TAG_RE
    paired1_out.write_seq(n,f,q,c)
  elsif n=~ PAIRED2_TAG_RE
    paired2_out.write_seq(n,f,q,c)
  else
    STDERR.puts "Aborting due to ERROR in file: #{n} doens't match neither left (#{paired1_tag}) nor right (#{paired2_tag}) tags"
    exit
  end
  
  if ((f_file.num_seqs%10000) == 0)
    puts "Count: #{f_file.num_seqs}"
  end
  
  
end

f_file.close

paired1_out.close
paired2_out.close




