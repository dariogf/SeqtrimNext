#!/usr/bin/env ruby

require 'scbi_fasta'

if ARGV.count!=3
  puts "Usage: #{File.basename($0)} database min_size name_list"
  exit
end
min_size = ARGV[1].to_i

# read keywords
keywords=File.read(ARGV[2]).split("\n")

# convert all to upcase
keywords.map { |keyword| keyword.upcase!}

# puts "Search keywords"
# keywords.each { |keyword| puts keyword}

fqr=FastaQualFile.new(ARGV[0])

all=[]

fqr.each do |n,s,c|
  keywords.each do |keyword|
    if s.length<=min_size
      # all+=c.split(" ")
      if c.upcase.index(keyword)
         # puts "[#{s.length.to_s}] - #{n} - #{c}"
        puts ">#{n} #{c}\n#{s}"
        break
      end
    end
  end
end

# puts all.sort.uniq.reject{|e| e=~/\d/}

fqr.close
