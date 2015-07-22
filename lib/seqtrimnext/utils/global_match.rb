class GMatch
  
  attr_accessor :offset
  attr_accessor :match
  
  
end

class Regexp
  def global_match(input_str,overlap_group_no = 0)
    res = []
    
    str=input_str
    
    last_end = 0
    
    loop do
      str = input_str.slice(last_end,input_str.length-last_end)
      if str.nil? or str.empty?
        break
      end
      
      m = self.match(str)
      # puts "find in: #{str}"
      
      if !m.nil?
        # puts m.inspect
        
        
        new_match=GMatch.new()
        new_match.offset = last_end
        new_match.match = m
        
        res.push new_match
        
        if overlap_group_no == 0
          last_end += m.end(overlap_group_no)
        else
          last_end += m.begin(overlap_group_no)
        end
        
      else
        break
      end
      
    end
    
    
    return res
  end
    
  
  # def global_match(str, &proc)
  #     retval = nil
  #     loop do
  #       res = str.sub(self) do |m|
  #         proc.call($~) # pass MatchData obj
  #         ''
  #       end
  #       break retval if res == str
  #       str = res
  #       retval ||= true
  #     end
  #   end
end
