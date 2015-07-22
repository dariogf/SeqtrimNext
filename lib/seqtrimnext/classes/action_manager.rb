#########################################
# Author:: Almudena Bocinos Rioboo
# This class provided the methods to apply actions to sequences
 #########################################
require 'seqtrim_action' 
class ActionManager 
  
  #Storages the necessary plugins specified in 'plugin_list' and start the loading of plugins
  def initialize 
    
    load_actions_from_files
  end
  
  def self.new_action(start_pos,end_pos,action_type) 
     action_class = Object.const_get(action_type)
    # DONE mirar si la action_class es de verdad una action existente 
     res = nil     
     if !action_class.nil? && action_class.ancestors.include?(SeqtrimAction)
       res= action_class.new(start_pos,end_pos)
     else
       #$LOG.error ' Error. Don´t exist the action: ' + action_class.to_s
       puts ' Error. The action : ' + action_class.to_s+ ' does not exists'
     end
     return res
  end
  
  
  
  
  # Iterates by the files from the folder 'actions', and load it
  def load_actions_from_files
    ignore = ['.','..','seqtrim_action.rb']
    #carpeta=Dir.open("progs/ruby/seqtrimii/actions")
    actions_path = File.expand_path(File.join(File.dirname(__FILE__), "..","actions"))
    if !File.exists?(actions_path)
    	raise "Action folder does not exists"
    end
    carpeta=Dir.open(actions_path)

    carpeta.entries.each do |action|
      if !ignore.include?(action)
          require action
      end # end  if
    end # end  each
  end # end  def
  
end
