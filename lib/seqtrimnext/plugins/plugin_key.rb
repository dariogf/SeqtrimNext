require "plugin"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginKey                                                     
# Inherit: Plugin
########################################################

class PluginKey < Plugin   
  
  
   #Begins the pluginKey's execution to warn where is a key in the sequence "seq"    
   def exec_seq(seq,blast_query)

     $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: marking key into the sequence" 
     # blast_table_results.inspect        
     
     actions=[]
     
     key_size=0
     # mid_size=0
     key_beg,key_end=[0,3]
     key_size=4
     key=seq.seq_fasta[0..3].upcase
     
     a = seq.new_action(key_beg,key_end,'ActionKey') # adds the actionKey to the sequence
     actions.push a       
     
     #Add actions  
     seq.add_actions(actions)
     
     
     if @group_by_key
       
       seq.add_file_tag(0,'key_' + key, :dir)
       add_stats('key_tag',key)
     end
     
     add_stats('key_size',key_size)
     # add_stats('mid_size',mid_size)
           

     
   end
 
  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]
    
    # self.check_param(errors,params,'blast_evalue_mids','Float')
    # self.check_param(errors,params,'blast_percent_mids','Integer')
    comment='sequences containing with diferent keys (barcodes) are saved to separate folders'
	  default_value='false'
	  params.check_param(errors,'use_independent_folder_for_each_key','String',default_value,comment)
    
    
    return errors
  end
  
  
end
