#!/usr/bin/env ruby

require 'json'

class Array
  
  def sum
    r=0
    each do |e|
      r+=e
    end
    return r
  end
  
end

class ScbiStats
  
  def initialize(values)
    
    @values=values
    
    
  end
  
  def get_window_value(i,window_size=10)
    start_pos=[0,i-window_size].max
    
    end_pos=[@values.length,i+window_size].min
    # puts "#{@values[start_pos..end_pos]} => #{@values[start_pos..end_pos].sum}"
    return @values[start_pos..end_pos].sum
  end
  
  def fat_mode(window_size=10)
    
    fat_modes=[]
    max_fat=0
    
    @values.length.times do |i|
      fat=get_window_value(i)
      
      fat_modes << fat
      
      if fat_modes[max_fat] < fat
        max_fat=i
      end
      
    end
    # puts fat_modes
    return max_fat
    # puts @values.length, @fat_modes.length
  end
  
end


# istat=JSON.parse(File.read('initial_stats.json'))
# 
# x=[]
# istat['qv'].each do |qv|
#   x<< qv['tot'].to_i
#   
# end
# # Usage:
# 
# s=ScbiStats.new(x)
# 
# puts s.fat_mode
