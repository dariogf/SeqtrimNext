require "plugin"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginLinker                                                     
# Inherit: Plugin
########################################################
class PluginLinker < Plugin
  MAX_LINKER_ERRORS=2
  #-------------------------------------------------------------------------
  #It's created an ActionInsert or ActionShortInsert before the ActionLinker 
  #Used: in class PluginLinker and PluginMid
  #-------------------------------------------------------------------------
  # def add_action_before_linker(p_q_beg,size_insert,actions,seq)
  # 
  #    size_min_insert = @params.get_param('size_min_insert').to_i
  #    if ((p_q_beg>0) && (size_insert>=size_min_insert))         #if linker's positions are right    
  #       #It's created an ActionInsert or ActionShortInsert before the ActionLinker    
  #       a = seq.new_action(0,p_q_beg-1,"ActionInsert") # adds the ActionInsert to the sequence before adding the actionMid
  #       actions.push a
  #    elsif (p_q_beg>0)  #if linker's positions are right and insert's size is short
  #      #It's created an ActionShortInsert before the ActionLinker
  #      a = seq.new_action(0,p_q_beg-1,"ActionShortInsert") # adds the ActionInsert to the sequence before adding the actionMid
  #       actions.push a 
  #    end
  #    
  #  end  
  
  #-------------------------------------------------------------------------
  #It's created an ActionInsert or ActionShortInsert after the ActionLinker 
  #-------------------------------------------------------------------------
  # def add_action_after_linker(p_q_end,size_insert,actions,seq) 
  #   
  #   size_min_insert = @params.get_param('size_min_insert').to_i     
  # 
  #   if ((p_q_end<seq.seq_fasta.size-1) && (size_insert>=size_min_insert) )  #if linker's positions are right 
  #     #It's created an ActionInsert after the ActionLinker
  #     a = seq.new_action(p_q_end+1,seq.seq_fasta.size-1,"ActionInsert") # adds the ActionInsert to the sequence before adding the actionMid
  # 
  #     actions.push a
  #       
  #   elsif (p_q_end<seq.seq_fasta.size-1)   #if linker's positions are right and insert's size is short 
  #     #It's created an ActionInsert after the ActionLinker
  #     a = seq.new_action(p_q_end+1,seq.seq_fasta.size-1,"ActionShortInsert") # adds the ActionInsert to the sequence before adding the actionMid
  # 
  #     actions.push a 
  #   end
  #   
  # end
  # 
  
  def sum_quals(a)
	  	res = 0
	  	
	  	a.map{|e| res+=e}
	  	
		return res
  end
  
  def merge_hits_with_same_qbeg_and_qend(hits)
	  	res =[]
  
  		hits.each do |hit|
				if !res.find{|h| (h.q_beg==hit.q_beg) && (h.q_end==hit.q_end)}
					res.push hit
				end
  		end  

  		return res
  end
 
  def do_blasts(seqs)
     # find MIDS  with less results than max_target_seqs value 
     blast = BatchBlast.new("-db #{@params.get_param('linkers_db')}",'blastn'," -task blastn-short  -evalue #{@params.get_param('blast_evalue_linkers')} -perc_identity #{@params.get_param('blast_percent_linkers')}")  #get linkers          

     $LOG.debug('BLAST:'+blast.get_blast_cmd)

     fastas=[]

     seqs.each do |seq|
      fastas.push ">"+seq.seq_name
      fastas.push seq.seq_fasta
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
     $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: looking for linker into the sequence"
     
     # key_beg,key_end=search_key(seq,0,3)   if false       
     # blast = BatchBlast.new("-subject #{File.join($FORMATTED_DB_PATH,'linkers.fasta')}",'blastn'," -task blastn  -evalue #{@params.get_param('blast_evalue_linkers')} -perc_identity #{@params.get_param('blast_percent_linkers')}")  #get linkers
     # blast = BatchBlast.new("-db #{File.join($FORMATTED_DB_PATH,'linkers.fasta')}",'blastn'," -task blastn-short  -evalue #{@params.get_param('blast_evalue_linkers')} -perc_identity #{@params.get_param('blast_percent_linkers')}")  #get linkers          
     # 
     # blast_table_results = blast.do_blast(seq.seq_fasta)             #rise seq to linkers  executing over blast 
    

     #blast_table_results = BlastTableResult.new(res) 
     actions=[]  
     linker_size=0
          
     if (!blast_query.hits.empty?) #linker found
     
			linkers = merge_hits_with_same_qbeg_and_qend(blast_query.hits)

			if linkers.count ==1
			
         linker=linkers.first
         
         linker_size=linker.q_end-linker.q_beg+1
		     
		     if (linker.gaps+linker.mismatches>MAX_LINKER_ERRORS) # number of ERRORS and GAPs is higher than MAX_LINKER_ERRORS, 
		         seq.seq_rejected=true
		         seq.seq_rejected_by_message='linker with mismatches'
		         # @stats[:rejected_seqs]={'rejected_seqs_by_errors' => 1}
		         add_stats('rejected','by_linker_errors')
			 		   add_stats('linker_errors',linker.gaps+linker.mismatches)
		     else     
		       #Create an ActionLinker
		        a = seq.new_action(linker.q_beg,linker.q_end,'ActionLinker') # adds the ActionLinker to the sequence 
		        a.message = linker.subject_id 
		        a.tag_id = linker.subject_id
		        actions.push a  
		        
            # seq.add_file_tag(0, 'paired', :file)
		        
		        add_stats('linker_id',linker.subject_id)
		        add_stats('linker_id','total')
		        
		     end
		     
			else # multiple linkers found
			  q_begs=[]
			  q_ends=[]

			  linker_count=linkers.count
			  
				linkers.each do |linker|
					#puts "*MULTILINKER* #{linker.subject_id[0..40].ljust(40)} #{linker.q_beg.to_s.rjust(6)} #{linker.q_end.to_s.rjust(6)} #{linker.s_beg.to_s.rjust(6)} #{linker.s_end.to_s.rjust(6)}"
					q_begs.push linker.q_beg
					q_ends.push linker.q_end

				end
       		
     		first_linker = linkers.first
     		last_linker = linkers.last
       	
   		  a = seq.new_action(q_begs.min,q_ends.max,'ActionMultipleLinker') # adds the ActionLinker to the sequence
        a.message = "#{linker_count} x #{first_linker.subject_id}"
        a.tag_id = first_linker.subject_id
        
        #determine with part (left or right) has the best quality
        left_quals = seq.seq_qual[0,q_begs.min]
			  sum_left=sum_quals(left_quals)
        
        right_quals = seq.seq_qual[q_ends.max+1..seq.seq_qual.length]
        sum_right=sum_quals(right_quals)
        
        if sum_left>=sum_right
	        a.right_action=true
	      else
	      		a.left_action=true
	      	end
        
        #puts "SUM QUAL LEFT:#{sum_left} count:#{left_quals.length}"
        #puts "SUM QUAL RIGHT:#{sum_right} count:#{right_quals.length}"
        
        
        actions.push a
        
        add_stats('multiple_linker_id',first_linker.subject_id)
        add_stats('multiple_linker_id','total')
        add_stats('multiple_linker_count',linker_count)
        
#				puts "=== > seq_qual: #{seq.seq_qual.count}"
#        seq.get_qual_inserts.each do |qi|
#        		puts "==> #{qi.join(' ')}"
#        end

  			end
  			
  		else # no linker found
	  		add_stats('without_linker',linker_size)
    end
	    
	    
    if !actions.empty?
		  #Add actions
		  seq.add_actions(actions)
	  end

  end
 
  
  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]  
    
    comment='Blast E-value used as cut-off when searching for linkers in paired-ends'
		default_value = 1e-10
		params.check_param(errors,'blast_evalue_linkers','Float',default_value,comment)
		
		comment='Minimum required identity (%) for a reliable linker'
		default_value = 95
		params.check_param(errors,'blast_percent_linkers','Integer',default_value,comment)

    comment='Path for 454 linkers database'
		default_value = File.join($FORMATTED_DB_PATH,'linkers.fasta')
		params.check_param(errors,'linkers_db','DB',default_value,comment)
		
    
    return errors
  end
  
  
end
