#!/usr/bin/env ruby

require 'json'
require 'scbi_fastq'

if ARGV.count != 2


end


# >Cluster 0
# 0       216aa, >E9LAHD006DQKVK... *
# >Cluster 1
# 0       203aa, >E9LAHD006DODWR... *
# >Cluster 2
# 0       198aa, >E9LAHD006DQCDS... *
# >Cluster 3
# 0       195aa, >E9LAHD006DQURO... *
# 1       172aa, >E9LAHD006DOSHR... at 93.02%
# 2       172aa, >E9LAHD006DSV4P... at 93.02%
# 3       172aa, >E9LAHD006DI00Q... at 93.02%
# 4       172aa, >E9LAHD006DR7MR... at 93.02%
# 5       175aa, >E9LAHD006DTDA7... at 90.86%
# 6       172aa, >E9LAHD006DVCR3... at 93.02%
# 7       172aa, >E9LAHD006DHY3H... at 93.02%
# 8       177aa, >E9LAHD006DI52X... at 90.96%



def load_repeated_seqs(file_path,min_repetitions)
  clusters=[]
  # count=0
  current_cluster=[]
  if File.exists?(file_path)
    # File.open(ARGV[0]).each_line do |line|
    # $LOG.debug("Repeated file path:"+file_path)

    File.open(file_path).each_line do |line|

      if line =~ /^>Cluster/
        if !current_cluster.empty? && (current_cluster.count <= min_repetitions)
          clusters += current_cluster
        end
        
        # count=0
        current_cluster=[]
      elsif line =~ />([^\.]+)\.\.\.\s/
        current_cluster << $1
      end

    end

    if !current_cluster.empty? && (current_cluster.count <= min_repetitions)
      clusters += current_cluster
    end

    # $LOG.info("Repeated sequence count: #{@clusters.count}")
  else
    # $LOG.error("Clustering file's doesn't exists: #{@clusters.count}")

  end

  return clusters

end


def remove_singletons_from_file(input_file_path,singletons)
  fqr=FastqFile.new(input_file_path)

  out=FastqFile.new(input_file_path+'_without_singletons','w+')
  
  
  fqr.each do |n,f,q,c|
    if !singletons.include?(n)
      out.write_seq(n,f,q,c)
    end
  end
  
  out.close
  fqr.close
  
end

input_file_path=ARGV.shift
min_repetitions = ARGV.shift.to_i

`cd-hit -i #{input_file_path} -o clusters`

singletons = load_repeated_seqs('clusters.clrs',min_repetitions)

remove_singletons_from_file(input_file_path,singletons)

# puts singletons.to_json
