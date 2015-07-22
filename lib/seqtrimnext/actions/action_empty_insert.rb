require "seqtrim_action"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute ActionShortInserted                                                     
# Inherit: Plugin
########################################################

class ActionEmptyInsert < SeqtrimAction

  def initialize(start_pos,end_pos)
    super(start_pos,end_pos)    
    @cut =false
    @informative = true
  end

def apply_decoration(char)
  return char
end             
              
end
