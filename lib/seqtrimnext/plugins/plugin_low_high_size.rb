########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginLowHighSize

#                                                     
# Inherit: Plugin
########################################################
require "plugin"


class PluginLowHighSize < Plugin
  
  
 # Begins the plugin_low_high_size's execution with the sequence "seq"

 def exec_seq(seq,blast_query)

    $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: checking low or high size of the sequence"    
    
    min_size = @params.get_param('min_sequence_size_raw').to_i #min_size is: mean - 2dev
    max_size = @params.get_param('max_sequence_size_raw').to_i #max_size is: mean + 2dev
    #add_stats('rejected_seqs',seq.seq_fasta.length)
    actions=[]
    
    if ((max_size>0 && (seq.seq_fasta.length>max_size)) || (seq.seq_fasta.length<min_size))  #if length of sequence is out of (-2dev,2dev)
      $LOG.debug "#{seq.seq_name} rejected by size #{seq.seq_fasta.length} "
      type='ActionLowHighSize'
      # seq.add_action(0,seq.seq_fasta.length,type)  
      a = seq.new_action(0,seq.seq_fasta.length,type)
      a.message = 'low or high size'
      seq.seq_rejected = true 
      seq.seq_rejected_by_message= 'size out of limits'
       
      add_stats('rejected_seqs',seq.seq_fasta.length)
      actions.push a
      seq.add_actions(actions)
    
    end  
    
    
  end
 

  ######################################################################
  #---------------------------------------------------------------------

  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]
    
    comment='Minimum size for a raw input sequence to be analysed (shorter reads are directly rejected without further analysis)'
		default_value = 40
		params.check_param(errors,'min_sequence_size_raw','Integer',default_value,comment)

    #self.check_param(errors,params,'max_sequence_size_raw','Integer')
    
    
    return errors
  end
  

  
end
