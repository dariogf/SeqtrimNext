#!/usr/bin/env ruby

require 'json'

def get_json_data(file_path)
  
  file1 = File.open(file_path)
  text = file1.read
  file1.close

  # puts text
  # # wipe text
  # text=text.grep(/^\s*[^#]/).to_s

  # decode json
  data = JSON.parse(text)

  return data
end


# extract params loading to external file in ingebiol

params={}

params['vector_db_field']='vectors_db'
params['primers_db_field']='primers_db'
params['contaminants_db_field']='contaminants_db'
params['user_contaminants_db_field']='user_contaminants_db'
params['species_field']='genus'
params['min_insert_size_field']='min_insert_size_trimmed'
params['min_paired_insert_size_field']='min_insert_size_paired'
params['min_quality_value_field']='min_quality'

if ARGV.count!=2
  puts "#{$0} ingebiol_params_file.json seqtrim_params_file"
  exit(-1)
end

input_file = ARGV[0]

params_file=ARGV[1]

if !File.exists?(input_file)
  puts "File #{input_file} doesn't exists"
  exit(-1)
end

if !File.exists?(params_file)
  puts "File #{params_file} doesn't exists"
  exit(-1)
end

sq_params=File.open(params_file,'r')

data=get_json_data(input_file)

# puts data.keys
# puts data['vector_db_field']

# replace params

# sq_params.each_line do |line|
#   line.chomp!
#   
#   if line =~ /^\s*(.+)\s*=\s*(.+)\s*/
#     puts $1,$2
#   end
#   
# end

sq_params=File.open(params_file,'a+')

sq_params.puts ""

data.each do |k,v|

  sq_name=params[k]
  # puts k,sq_name

  if sq_name && v && !v.empty? 
    sq_params.puts "#{sq_name}=#{v}"
  end
  
end

sq_params.close