require "plugin"

require "make_blast_db"
########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginIgnoreRepeated                                                     
# Inherit: Plugin
########################################################

class PluginIgnoreRepeated < Plugin

 SIZE_SEARCH_IN_IGNORE=15
 
 #Begins the plugin1's execution to warn that there are repeated sequences,  and disables all but one"
 def exec_seq(seq,blast_query)

    $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: searching sequence repeated at input file" 

    fasta_input=@params.get_param('truncated_input_file')
    
    blast = BatchBlast.new("-db #{fasta_input}" ,'blastn'," -task blastn-short -searchsp #{SIZE_SEARCH_IN_IGNORE} -evalue #{@params.get_param('blast_evalue_ignore_repeated')} -perc_identity #{@params.get_param('blast_percent_ignore_repeated')}")  #get contaminants
    
    p_start = @params.get_param('piro_repeated_start').to_i
    p_length = @params.get_param('piro_repeated_length').to_i
    
    
    blast_table_results = blast.do_blast(seq.seq_fasta[p_start,p_length])             #rise seq to contaminants  executing over blast
    
    #blast_table_results = BlastTableResult.new(res)
    
 
     type = "ActionIgnoreRepeated"        
     
     # @stats[:rejected_seqs]={}    
       
     actions=[]     
     blast_table_results.querys.each do |query|
                                               
           # puts "BLAST IGUALES:"
           # puts res.join("\n")       
       if query.size>1   
         names = query.hits.collect{ |h| 
              if h.align_len > (p_length-2)
                h.subject_id
              end
         }
             
         names.compact!   
          
          # puts "IGUALES:" + names.size.to_s 
          #            puts names.join(',')               
          
          if !names.empty?
             names.sort!
				     
             if (names[0] != seq.seq_name)   # Add action when the sequence  is repeated 
				     #  if true 
				        a = seq.new_action(0,0,type)
				        a.message = seq.seq_name  + ' equal to ' + names[0]    
				        actions.push a
				        seq.seq_rejected=true   
				        seq.seq_rejected_by_message='repeated'
				        seq.seq_repeated=true       
				        
                # @stats[:rejected_seqs]={'rejected_seqs_by_repe' => 1}   
                add_stats('rejected_seqs','rejected_seqs_by_repe') 
                 # puts "#{names[0]} != #{seq.seq_name} >>>>>>"       
				     end                                                               
         end
         
       end       
       
     end 
     
     seq.add_actions(actions)
     
  end



  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]
                  
     # self.check_param(errors,params,'fasta_file_input','String')
     self.check_param(errors,params,'blast_evalue_ignore_repeated','Float') 
     self.check_param(errors,params,'blast_percent_ignore_repeated','Integer')
     self.check_param(errors,params,'piro_repeated_start','Integer')
     self.check_param(errors,params,'piro_repeated_length','Integer')
    return errors
  end
  
  
end
