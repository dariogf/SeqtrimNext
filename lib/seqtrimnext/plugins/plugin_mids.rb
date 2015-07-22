require "plugin"
require 'recover_mid'
include RecoverMid

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginMids                                                     
# Inherit: Plugin
########################################################

class PluginMids < Plugin   
  SIZE_SEARCH_MID=20  
  MAX_MID_ERRORS = 2
  #MIN_MID_SIZE = 7  # very important, don't touch 
  # DB_MID_SIZE = 10  # DONE read formatted db and save the mid sizes    
  
  def do_blasts(seqs)
     # find MIDS  with less results than max_target_seqs value 
     blast = BatchBlast.new("-db #{@params.get_param('mids_db')}",'blastn'," -task blastn-short    -perc_identity #{@params.get_param('blast_percent_mids')} -max_target_seqs 4 ")  #get mids 
     $LOG.debug('BLAST:'+blast.get_blast_cmd)

     fastas=[]
     
     seqs.each do |seq|
      fastas.push ">"+seq.seq_name
      fastas.push seq.seq_fasta[0..SIZE_SEARCH_MID]
     end
     
     # fastas=fastas.join("\n")
     
     blast_table_results = blast.do_blast(fastas)
     
     # puts blast_table_results.inspect
    
     return blast_table_results
  end
  
  
  def exec_seq(seq,blast_query)
    if blast_query.query_id != seq.seq_name
      raise "Blast and seq names does not match, blast:#{blast_query.query_id} sn:#{seq.seq_name}"
    end

     
     $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: looking for mids into the sequence"   
      

     # blast_table_results = blast.do_blast(seq.seq_fasta[0..SIZE_SEARCH_MID])             # execute blast to find mids
     # blast_table_results.inspect
     
     actions=[]
     file_tag='no_MID'
     
     key_size=0
     mid_size=0
     
     key_already_found=!seq.get_actions(ActionKey).empty?
     
     mid_errors=[]    #number of MIDs with 1 error, and number of MIDs with 2 errors
     mid_id=[] #number of MIDs from each type
     mid_found = false
     
     if !blast_query.hits.empty? # mid found 
       
       # blast_query.hits.sort!{|h1,h2| h1.q_beg <=> h2.q_beg}
       # puts blast_query.count.to_s + "============== #{blast_query.hits[0].inspect}"
       # blast_table_results.inspect
                                  
       # select first sorted mid
       mid=blast_query.hits[0]
       
       # find a not reversed mid
       if mid.reversed
         
         blast_query.hits.each do |hit|
          if !hit.reversed # take the first non-reversed one
             mid = hit
             break
          end
         end

       end
       
       # puts "DOES THE MID HAVE ENOUGHT SIZE? #{mid.q_end-mid.q_beg+1} >= #{MIN_MID_SIZE}?"
       mid_size=mid.q_end-mid.q_beg+1
       
       db_mid=@params.get_mid(mid.subject_id)
       db_mid_size = db_mid.size  #get mid's size from DB   
       
       mid_initial_pos=mid.q_beg-mid.s_beg
       has_full_key=false
       if !@params.get_param('sequencing_key').nil? && !@params.get_param('sequencing_key').empty?
       	has_full_key = !seq.seq_fasta.index(@params.get_param('sequencing_key')).nil?
       end
       
       if mid.reversed
       	  # discard mid
       elsif (mid.gaps+mid.mismatches > MAX_MID_ERRORS) # number of ERRORS and GAPs is higher than MAX_MID_ERRORS, 
          # discard mid
       elsif (mid.q_beg<3) # if found mid starts below 3, then discard it 
         # discard mid
       elsif (has_full_key && (mid_initial_pos >=6))
         # discard mid
       elsif (!has_full_key && (mid_initial_pos >=7))
         # discard mid
       elsif (mid_size >= db_mid_size-1)  # MID found and MID's size is enought, THEN create key and mid
 			 		 
		       key_beg,key_end=[0,mid.q_beg-1]
		       key_size=mid.q_beg
		      
		       # Create an ActionKey before the ActionMid
		       if key_size>0 && !key_already_found                                    
		         a = seq.new_action(key_beg,key_end,"ActionKey") # adds the actionKey to the sequence
		         actions.push a 
		       end      
         
 					 #Create an ActionMid 
           a = seq.new_action(mid.q_beg,mid.q_end,"ActionMid") # adds the ActionMids to the sequence   
           a.message = mid.subject_id
           a.tag_id = mid.subject_id
           file_tag = mid.subject_id
           actions.push a
         
           mid_found = true
         
      elsif (mid_size >= db_mid_size-3)
        # To recover a MID it must start or end in one edge
        if (mid.s_beg==0) || (mid.s_end==mid_size)

					new_q_beg, new_q_end, recovered_size,recovered_mid = recover_mid(mid, db_mid, seq.seq_fasta[0..SIZE_SEARCH_MID])
					
					$LOG.debug("Recover mid: #{recovered_mid} valid (#{recovered_size} >= #{10-1}) = #{recovered_size>=10-1}, #{seq.seq_fasta[new_q_beg..new_q_end]}")

					if recovered_size >= db_mid_size-1
						mid_size = recovered_size
				
						# if MID found and MID's size is enought to recover a MID, THEN create an action key and mid 
						key_beg,key_end=[0,new_q_beg-1]
						key_size=new_q_beg
					
						$LOG.debug "RECOVER OUTPUT: #{new_q_beg} #{new_q_end} #{recovered_size}"

						#  if key_size > 4(or max_size_key) then seq.seq_rejected 

						# Create an ActionKey before the ActionMid
						if key_size>0 && !key_already_found
							a = seq.new_action(key_beg,key_end,"ActionKey") # adds the actionKey to the sequence
							actions.push a 
						end      

						#Create an ActionMid to a recovered mid
						a = seq.new_action(new_q_beg,new_q_end,"ActionMid") # adds the ActionMids to the sequence 
						a.message = "Recovered " + mid.subject_id
						a.tag_id = mid.subject_id
            file_tag = mid.subject_id
						actions.push a
						add_stats('recovered_mid_id',mid.subject_id)

						mid_found = true
			    end
		    end
		  end
    end
     
    if !mid_found && !key_already_found # MID not found, take only the key
       mid_size=0
       key_beg,key_end=[0,3]
       key_size=4
       a = seq.new_action(key_beg,key_end,'ActionKey') # adds the actionKey to the sequence
       actions.push a   
     end 
     
     #Add actions  
     seq.add_actions(actions)
     
     seq.add_file_tag(1, file_tag, :both)
     # seq.add_file_tag(2,'sequence')
     
     if (mid_found) # MID without errors
      
       add_stats('mid_id',mid.subject_id)
       add_stats('mid_id','total')

       #save MID count by ID
       add_stats(mid.subject_id,mid_size)
      
      	if (mid.gaps+mid.mismatches > 0)
				add_stats('mid_with_errors',mid.gaps+mid.mismatches)
      	end
       
     end
     
     if !key_already_found
       add_stats('key_size',key_size)
       add_stats('mid_size',mid_size)
     end
  end
 
  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]
    
    	comment='Blast E-value used as cut-off when searching for MIDs'
		default_value = 1e-10
		params.check_param(errors,'blast_evalue_mids','Float',default_value,comment)
		
		comment='Minimum required identity (%) for a reliable MID'
		default_value = 95
		params.check_param(errors,'blast_percent_mids','Integer',default_value,comment)
    
    comment='Path for MID database'
		default_value = File.join($FORMATTED_DB_PATH,'mids.fasta')
		params.check_param(errors,'mids_db','DB',default_value,comment)

    return errors
  end
  
  
end
