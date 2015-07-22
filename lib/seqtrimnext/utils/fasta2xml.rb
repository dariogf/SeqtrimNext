#!/usr/bin/env ruby


command_info="
#================================================
# Author: Almudena Bocinos Rioboo    
#
#
# Usage: fasta2xml.rb <fasta_file>  [> <out_file.xml>]
#
# Converts a fasta file to xml format (used for cabog)
#
# Prints to stdout, can be redirected to file with >
#
#================================================
\n";

#require "utils/fasta_utils"
require File.dirname(__FILE__) + "/utils/fasta_utils"

#receive one argument or fail
if ARGV.length != 1
  puts command_info;
  Process.exit(-1);
end

#get file name
file_name=ARGV[0];

#check if file exists
if !File.exist?(file_name)
  puts "File #{file_name} not found.\n";
  puts command_info;
  Process.exit(-1);
end

######################################
# Define a subclass to override events
######################################
class FastaProcessor< FastaUtils::FastaReader

  #override begin processing
  def on_begin_process()
      
    # print XML header
    puts "<?xml version=\"1.0\"?>\n<trace_volume>\n";
    
  end
 
  #override sequence processing
  def on_process_sequence(seq_name,seq_fasta)
    
    # prints the xml tags
    puts "<trace>\n\t<trace_name>#{seq_name}</trace_name>\n\t<clip_vector_left>1</clip_vector_left>\n\t<clip_vector_right>#{seq_fasta.length.to_s}</clip_vector_right>\n</trace>\n";
    
  end
  
  #override end processing
  def on_end_process()
  
    #print foot
    puts "</trace_volume>\n";
    
  end
   
end

#Create a new instance to process the file
f=FastaProcessor.new(file_name);
