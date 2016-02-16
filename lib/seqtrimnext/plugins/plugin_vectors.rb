require "plugin"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginVectors                                                     
# Inherit: Plugin
########################################################

class PluginVectors < Plugin 
  
  # MIN_VECTOR_SIZE=30
  #   MAX_TO_EXTREME=(MIN_VECTOR_SIZE/2).to_i 
  MAX_TARGETS_SEQS=20 #MAXIMUM NUMBER OF DIFFERENT ALIGNED SEQUENCES TO  KEEP FROM BLAST DATABASE   
  
  def near_to_extrem(c,seq,min_vector_size)
    max_to_extreme=(min_vector_size/2).to_i
    return ((c.q_beg-max_to_extreme<0) || (( c.q_end+max_to_extreme)>=seq.seq_fasta.size-1) ) #return if vector is very near to the extremes of insert)
  end      
  
  def all_vector_in_linker(vector_beg,vector_end,seq)
    linkers=seq.get_actions(ActionLinker) 
    # res=((linkers.count>=1) && (vector_beg>=linkers[0].start_pos) && (vector_end<=linkers[0].end_pos)) 
    # puts " RES #{res}  insert-start #{seq.insert_start} #{linkers.count}>=1 #{vector_beg+seq.insert_start}>=#{linkers[0].start_pos}) && #{vector_end+seq.insert_start}<=#{linkers[0].end_pos})) "
    return  ((linkers.count>=1) && (vector_beg+seq.insert_start>=linkers[0].start_pos) && (vector_end+seq.insert_start<=linkers[0].end_pos))
  end
  
 def do_blasts(seqs)
    # find MIDS  with less results than max_target_seqs value 
    blast = BatchBlast.new("-db #{@params.get_param('vectors_db')}",'blastn'," -task blastn-short -evalue #{@params.get_param('blast_evalue_vectors')} -perc_identity #{@params.get_param('blast_percent_vectors')} -culling_limit 1")  #get vectors

    $LOG.debug('BLAST:'+blast.get_blast_cmd)

    fastas=[]

    seqs.each do |seq|
     fastas.push ">"+seq.seq_name
     fastas.push seq.seq_fasta
    end

    # fastas=fastas.join("\n")

    #blast_table_results = blast.do_blast(fastas,:xml)
    
    t1=Time.now
    blast_table_results = blast.do_blast(fastas,:xml,false)
    add_plugin_stats('execution_time','blast',Time.now-t1)

    t1=Time.now
    blast_table_results = BlastStreamxmlResult.new(blast_table_results)
    add_plugin_stats('execution_time','parse',Time.now-t1)


    # puts blast_table_results.inspect

    return blast_table_results
 end


 def exec_seq(seq,blast_query)
   if blast_query.query_def != seq.seq_name
     raise "Blast and seq names does not match, blast:#{blast_query.query_def} sn:#{seq.seq_name}"
   end
  
    $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: looking for vectors into the sequence " 
  
    #blast contra contaminantes
    
    # blast = BatchBlast.new("-db #{File.join($FORMATTED_DB_PATH,'vectors.fasta')}",'blastn'," -task blastn-short -evalue #{@params.get_param('blast_evalue_vectors')} -perc_identity #{@params.get_param('blast_percent_vectors')} -culling_limit 1")  #get vectors
 
    # blast_table_results = blast.do_blast(seq.seq_fasta,:xml)             #rise seq to contaminants  executing over blast
    type = "ActionVectors"
            
    # puts res
    #     blast_table_results.inspect 
    # blast_table_results.querys.each do |query|     # adds the correspondent action to the sequence
    #      query.hits.each do |hit|
    #        seq.add_action(hit.q_beg,hit.q_end,type)
    #      end
    #    end
    
  vectors=[]
  vectors_ids=[]
  # blast_table_results.querys.each do |query|     # first round to save vectors without overlap     
      # vectors_ids.push query.hits.subject_id if (not vectors_ids.include?(query.hits.subject_id)) 
      merge_hits(blast_query.hits,vectors,vectors_ids)
  # end 
  
  
  
  begin 
    vectors2=vectors                            # second round to save vectors without overlap
    vectors = []
    merge_hits(vectors2,vectors)
  end until (vectors2.count == vectors.count) 

	
  actions = [] 
  vectors_size=0
  min_vector_size=@params.get_param('min_vector_seq_presence').to_i 
  
  vectors.each do |v|                           # adds the correspondent action to the sequence
     
    	 #puts "*VECTOR* #{v.subject_id[0..40].ljust(40)} #{v.q_beg.to_s.rjust(6)} #{v.q_end.to_s.rjust(6)} #{v.s_beg.to_s.rjust(6)} #{v.s_end.to_s.rjust(6)}"

     vector_size=v.q_end-v.q_beg+1  
   # puts " in PLUGIN VECTOR previous to add action #{seq.insert_start} #{seq.insert_end}"   
    # if ((vector_size>=MIN_VECTOR_SIZE) || ((vector_size<MIN_VECTOR_SIZE) && near_to_extrem(v,seq)))
    if (near_to_extrem(v,seq,10) || (vector_size>=min_vector_size)   )
      # puts " near #{near_to_extrem(v,seq,min_vector_size)} #{vector_size}>=#{min_vector_size}"
      #c.q_end+seq.insert_start+max_to_end)>=seq.seq_fasta_orig.size-1)  #if ab adapter is very near to the end of original sequence  
      
      piro_on=@params.get_param('next_generation_sequences').to_s
      
      if (((piro_on=='true')  && (!seq.range_inside_action_type?(v.q_beg,v.q_end,ActionLinker)) && (!seq.range_inside_action_type?(v.q_beg,v.q_end,ActionMultipleLinker)))    ||   # if vectors DB not is contained inside detected linkers
           (piro_on=='false'))

				 # if vector is too big, and it isn't in an extreme, then it is an unexpected vector
         if !near_to_extrem(v,seq,min_vector_size)
       		type = 'ActionUnexpectedVector'

          if @params.get_param('middle_vector_rejects').to_s=='true'
    			  seq.seq_rejected=true
  				  seq.seq_rejected_by_message='unexpected vector'
          end
				  
				  add_stats('rejected','unexpected_vector')

       	 end

         
         a = seq.new_action(v.q_beg,v.q_end,type)
         a.message = v.definition  
         # a.found_definition.push  v.subject_id    # save the vectors definitions, each separately    
         a.found_definition=vectors_ids    # save the vectors definitions, each separately   
         a.reversed = v.reversed        
         a.cut=false if (piro_on=='true')  # vectors don't cut when piro is on  
          
         # puts "piro on #{piro_on}  vector cut #{a.cut}  ________________|||||||||| " 
         #          puts " no piro" if (piro_on=='false')    
          
         actions.push a   

         # @stats[:vector_size]={vector_size => 1} 
         add_stats('vector_size',vector_size) 
         vectors_ids.each do |v|
           add_stats('vectors_ids',v)
         end
      end
    end
    
  end 
  
  seq.add_actions(actions) 
  #
        
  end

  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[] 
    

    comment='Blast E-value used as cut-off when searching for vector fragments'
		default_value = 1e-1
		params.check_param(errors,'blast_evalue_vectors','Float',default_value,comment)
		
		comment='Minimum required identity (%) for a reliable vector fragment'
		default_value = 90
		params.check_param(errors,'blast_percent_vectors','Integer',default_value,comment)
		
    comment='Correct sequences could contain vectors only close to the read end (not within the sequence). The following variable indicates the number of nucleotides from the 5\' or 3\' end that are allowed for considering a vector fragment located at the end. Otherwise, the vector fragment will be qualified as internal and the sequence will be rejected'
		default_value = 8
		params.check_param(errors,'max_vector_to_end','Integer',default_value,comment)
		
		comment='If a vector fragment is qualified as internal, the fragment should be long enough to be sure that it is a true vector fragment. This is the minimum length of a vector fragment that enables sequence rejection by an internal, unexpected vector'
		default_value = 50
		params.check_param(errors,'min_vector_seq_presence','Integer',default_value,comment)
		
		
    comment='Vectors database path'
		default_value = File.join($FORMATTED_DB_PATH,'vectors.fasta')
		params.check_param(errors,'vectors_db','DB',default_value,comment)

    comment='Rejects sequences with vectors in the middle'
    default_value = 'true'
    params.check_param(errors,'middle_vector_rejects','String',default_value,comment)


    # params.split_databases('vectors_db')
    
    return errors
  end
  
  
  
  
end
