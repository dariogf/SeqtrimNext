######################################
# Author:: Almudena Bocinos Rioboo
# This class creates the structures that storage the necessary values from an action
######################################


require 'term/ansicolor'
include Term::ANSIColor

class SeqtrimAction
  
  
  attr_accessor :start_pos ,  :end_pos, :message, :cut , :reversed , :left_action , :right_action  , :found_definition, :tag_id, :informative
  
  #  Creates the nexts values from  an action: start_position, end_position, type
  def initialize(start_pos,end_pos)
    # puts " #{start_pos} #{end_pos} #{self.class.to_s}"   
    
    @start_pos = start_pos.to_i
    @end_pos = end_pos.to_i        
    
    #@notes = '' 
    @left_action = false
    @right_action = false
    @message = ''
    @found_definition=[] #array when contaminant or vectors definitions are saved, each  separately
    @cut = false 
    @informative = false
    @reversed = false
    # puts " #{@start_pos} #{@end_pos} #{self.class.to_s}"  
    @tag_id =''
    
  end
  
  def apply_to(seq)   
       
    $LOG.debug " Applying #{self.class} to seq #{seq.seq_name} . BEGIN: #{@start_pos}   END: #{@end_pos}  " 
    
  end
  
  def description
    
    return "Action Type: #{self.class} Begin: #{start_pos} End: #{end_pos}"
  end
  
  def inspect
    description
  end
  
  
  def contains?(pos)
    return ((pos>=@start_pos) && (pos<=@end_pos))
  end

  
  def contains_action?(start_pos,end_pos,margin=10)
    #puts "#{start_pos}>=#{@start_pos-margin} && #{end_pos}<=#{@end_pos+margin} "
		return ((start_pos>=@start_pos-margin) && (end_pos<=@end_pos+margin))
  end
  
  def apply_decoration(char)
    return char
  end      
  

  
  def decorate(char,pos)
    if contains?(pos)
      return apply_decoration(char)
    else
      return char
    end
  end
  
  def type
    return self.class.to_s
  end  
  def action_type
    
    a_type='INFO'
    if !@informative
      a_type = 'LEFT'
      if right_action
        a_type = 'RIGHT'
      end
    end
    return a_type
    
  end
  
  def to_human(camel_cased_word)
    word = camel_cased_word.to_s.dup
    word.gsub!(/::/, '/')
    word.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1 \2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1 \2')
    word.tr!("-", " ")
    word.downcase!
    word.capitalize!
    word
  end
  
  def title
   return to_human(type.gsub('Action',''))
  end                                                      
  
  def near_left?(seq_fasta_size)
    return ((@start_pos - 0 ) < (seq_fasta_size - @end_pos))
  end
  
  
  def left_action?(seq_fasta_size)
     res = (@left_action || (!@right_action && near_left?(seq_fasta_size)))
     # @left_action = res
       
     return res
   end

   def right_action?(seq_fasta_size)
      res= (@right_action || !left_action?(seq_fasta_size))
      # @right_action = res
      return res
   end 
   
  def to_hash
     a = {}
     
     a[:type]=type
     a[:start_pos]=@start_pos
     a[:end_pos]=@end_pos
     a[:message]=@message
     
     return a
  end
  
  
end
