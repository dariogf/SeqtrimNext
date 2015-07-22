#!/usr/bin/env ruby
require 'stringio'
# require 'test/unit'
require 'seqtrimnext'
require 'json'
require 'gnuplot'

# ROOT_PATH=File.dirname(File.dirname(__FILE__))

# $: << File.expand_path(File.join(ROOT_PATH,'test'))
# $: << File.expand_path(File.join(ROOT_PATH,'classes'))
# $: << File.expand_path(File.join(ROOT_PATH,'plugins'))
# $: << File.expand_path(File.join(ROOT_PATH,'utils'))

if ARGV.empty?
puts "Usage: #{$0} stats.json initial_stats.json"
exit
end

d=Dir.glob(File.expand_path(File.join(ROOT_PATH,'plugins','*.rb')))

# puts d.entries
# puts "="*20

require 'plugin'

# require 'params'

d.entries.each do |plugin|
	require  plugin
  # puts "Requiring #{plugin}"
end

require 'graph_stats'

#load stats

r=File.read(ARGV[0])
stats=JSON::parse(r)


r2=File.read(ARGV[1])
init_stats=JSON::parse(r2)

gs=GraphStats.new(stats,init_stats)

puts "Graphs generated"
    
