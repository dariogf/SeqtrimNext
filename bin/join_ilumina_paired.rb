#!/usr/bin/env ruby

require 'scbi_fastq'

VERBOSE=false

if !(ARGV.count==3 or ARGV.count==5)
  puts "Usage: #{$0} paired1 paired2 output_base_name [paired1_tag paired2_tag]"
  
  exit
end

p1_path=ARGV[0]
p2_path=ARGV[1]
output_base_name=ARGV[2]

paired1_tag='/1'
paired2_tag='/2'

if (ARGV.count==5)
  paired1_tag=ARGV[3]
  paired2_tag=ARGV[4]
end

PAIRED1_TAG_RE=/#{Regexp.quote(paired1_tag)}$/
PAIRED2_TAG_RE=/#{Regexp.quote(paired2_tag)}$/



if !File.exists?(p1_path)
  puts "File #{p1_path} doesn't exists"
  exit
end

if !File.exists?(p2_path)
  puts "File #{p2_path} doesn't exists"
  exit
end

def read_to_file(file)
  res ={}
  
  f_file = FastqFile.new(file,'r',:sanger, true)
  
  f_file.each do |n,f,q,c|
    res[n.gsub(PAIRED2_TAG_RE,'')]=[f,q,c]
    
    if ((f_file.num_seqs%10000) == 0)
      puts "Loading: #{f_file.num_seqs}"
    end
    
    
  end
  
  f_file.close

  return res
end



p1 = FastqFile.new(p1_path,'r',:sanger, true)

# p2 = FastqFile.new(p2_path,'r',:sanger, true)

p2 = read_to_file(p2_path)

puts "Sequences from #{p2_path} loaded. Total: #{p2.count}"


normal_out = FastqFile.new(output_base_name+'_normal.fastq','w',:sanger, true)
paired_out = FastqFile.new(output_base_name+'_all_paired.fastq','w',:sanger, true)
paired1_out = FastqFile.new(output_base_name+'_paired1.fastq','w',:sanger, true)
paired2_out = FastqFile.new(output_base_name+'_paired2.fastq','w',:sanger, true)


p1.each do |n1,f1,q1,c1|
  
  n1.gsub!(PAIRED1_TAG_RE,'')
  puts "Find #{n1}" if VERBOSE
  
  seq_in_p2=p2[n1]
  # p2.find{|e| e[0]==n1}
  
  if seq_in_p2
    n2=n1
    f2,q2,c2=seq_in_p2
    puts "  ===> PAIRED #{n2}" if VERBOSE
    
    paired_out.write_seq(n1+paired1_tag,f1,q1,c1)
    paired1_out.write_seq(n1+paired1_tag,f1,q1,c1)
    
    paired_out.write_seq(n2+paired2_tag,f2,q2,c2)
    paired2_out.write_seq(n2+paired2_tag,f2,q2,c2)

    p2.delete(n2)
    
  else
    puts "  ===> NOT PAIRED #{n1}"  if VERBOSE
    normal_out.write_seq(n1+paired1_tag,f1,q1,c1)
  end
  
  if ((p1.num_seqs%10000) == 0)
    puts p1.num_seqs
  end
    
end

# remaining at p2 goes to normal_out


p2.each do |seq_in_p2,v|
  n2=seq_in_p2
  f2,q2,c2=v
  
  normal_out.write_seq(n2+paired2_tag,f2,q2,c2)
  
end

p1.close
# p2.close

normal_out.close
paired_out.close
paired1_out.close
paired2_out.close




