#!/usr/bin/env ruby

require 'yajl'
require 'json'

unless file = ARGV.shift
  puts "\nUsage: $0 results.json action1 [action] [action] [action] ...\n\n"
  exit(0)
end


actions = ARGV
if actions.empty?
  puts "\nUsage: $0 results.json action1 [action] [action] [action] ...\n\n"
  exit(0)
end
  
json = File.new(file, 'r')

puts "Counting sequences with these actions: #{actions.join(",")}"
puts ""

total = 0
count = 0
separate_count={}

actions.each do |a|
  separate_count[a]=0
end

all_actions =[]

Yajl::Parser.parse(json) { |seq|

  total += 1
  action_names=seq['actions'].map {|a| a['type']}
  
  if (action_names & actions).count == actions.count
    count +=1
  end
  
  action_names.each do |a|
    if actions.include?(a)
        separate_count[a] += 1
    end
  end
  
  all_actions = (all_actions + action_names).uniq

}

puts "="*20 + "Separate count" + "="*20
separate_count.each do |k,v|
  puts "#{k} = #{v}"
  
end
puts "="*20 + "Summarized" + "="*20

puts "Number of sequences with all actions: #{count}"
puts "Total sequences: #{total}"

puts "\n"
puts "="*20 + "Other used actions" + "="*20
puts (all_actions-actions).join(',')


