########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginIndeterminations                                                     
# Inherit: Plugin
########################################################
require "plugin"
require "global_match"


class PluginIndeterminations < Plugin   
  

	def overlap(polys,mi_start,mi_end)
		
		# overlap = polys.find{|e| ( mi_start < e['end'])}
		overlap = polys.find{|e| ( overlapX?(mi_start,mi_end, e['begin'],e['end']) )}
		# puts " Overlap #{mi_start} #{mi_end} => #{overlap}"
		
		return overlap
	end

	MAX_RUBBISH = 3
 
 # Begins the pluginFindPolyAt's execution whit the sequence "seq"
 
 # Uses the param poly_at_length to look for at least that number of contiguous A's
  def find_polys(ta,seq,actions)

    minn = 4
    m2 = 1#(minn/2) 
    m4 = (minn/4)
    r = [-1,0,0]
    re2 = /((#{ta}{#{m2},})(.{0,3})(#{ta}{#{1},}))/i
    
    
    type='ActionIndetermination'
    poly_base = 'N'
    
    matches = re2.global_match(seq.seq_fasta,3)

		matches2 = /[^N]N$/.match(seq.seq_fasta)
		
		
    # HASH
    polys = []

    # crear una region poly nuevo
    poly = {}
    #i=0

    matches.each do |pattern2|

      #puts pattern2.match[0]
        m_start = pattern2.match.begin(0)+pattern2.offset
        m_end = pattern2.match.end(0)+pattern2.offset-1   
        
			 #puts "MATCH: #{m_start} #{m_end}"

       # does one exist in polys with overlap?

       # yes => group it, updated end

       # no => one new

       if (e=overlap(polys,m_start,m_end))
         
         e['end'] = m_end
         e['found'] = seq.seq_fasta.slice(e['begin'],e['end']-e['begin']+1)
         
       else
          poly={}
          poly['begin'] = m_start
          poly['end'] = m_end #  the next pos to pattern's end
          poly['found'] = seq.seq_fasta.slice(poly['begin'],poly['end']-poly['begin']+1)
          polys.push poly
       end
       
    end  
    
    
    poly_size=0 

    polys.each do |poly|
      #puts "NEW POLY: #{poly.to_json}"
    		
    		if poly_near_end(poly['end'],seq.seq_fasta) # near right side
    		  #puts "near end"
        a = seq.new_action(poly['begin'],poly['end'],type)
        a.right_action=true
        actions.push a
        
        poly_size=poly['end']-poly['begin']+1
        add_stats('size',poly_size)
      else
      		#puts "far of end"
	      if check_poly_length(poly['begin'],poly['end']) and (check_poly_percent(poly,poly_base))
	      		#puts "ok"
			    a = seq.new_action(poly['begin'],poly['end'],type)
		      a.right_action=true
		      actions.push a
		  
          if @params.get_param('middle_indetermination_rejects').to_s=='true'
		        seq.seq_rejected=true 
            seq.seq_rejected_by_message='Indeterminations in middle of sequence'
          end
		      
		      poly_size=poly['end']-poly['begin']+1
		      add_stats('size',poly_size)
	      end
      
      
      end
    end 
    
    
  end
  
    
 def check_poly_length(poly_start,poly_end)
   #puts "poly_length: #{1+(poly_end-poly_start)} nt"
   return (1+(poly_end-poly_start)) >= @params.get_param('poly_n_length').to_i
 end

 def check_poly_percent(poly,poly_base)
   
   # count Ts en poly['found']
   s=poly['found']
   ta_count = s.count(poly_base.downcase+poly_base.upcase)
   #puts "poly_percent: #{(ta_count.to_f/s.size.to_f)*100}%"
   res=((ta_count.to_f/s.size.to_f)*100 >= @params.get_param('poly_n_percent').to_i)
   
   return res
 end
 
 def poly_near_end(pos,seq_fasta)
 
 	max_to_end = @params.get_param('poly_n_max_to_end').to_i
 	
 	res = (pos>=(seq_fasta.length-max_to_end))
 	
 end
 
  
 def exec_seq(seq,blast_query)

     $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: removing indeterminations N+" 
     
     actions=[]
     
     # find simple indeterminations at end of sequence
			match=seq.seq_fasta.match(/[nN]+$/)
     
     if !match.nil?
			 found=match[0].length
       
       a = seq.new_action(seq.seq_fasta.length-found,seq.seq_fasta.length,'ActionIndetermination')
       a.right_action=true
       actions.push a       

       #Add actions  
       seq.add_actions(actions)
       actions=[]
       add_stats('indetermination_size',found)
	
     end
     
     find_polys('[N]',seq,actions)
     seq.add_actions(actions)
     
   end
 
  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]
    
 		comment='Minimum number of Ns within the sequence to be rejected by having an internal segment of indeterminations. Indeterminations at the end of the sequence will be removed regardless of their size and without rejecting the sequence'
		default_value = 15
		params.check_param(errors,'poly_n_length','Integer',default_value,comment)
    
 		comment='Minimum percent of Ns in a segment to be considered a valid indetermination'
		default_value = 80
		params.check_param(errors,'poly_n_percent','Integer',default_value,comment)

    comment='Maximum distance to the end of the sequence to be considered an internal segment'
    default_value = 15
    params.check_param(errors,'poly_n_max_to_end','Integer',default_value,comment)

 		comment='Rejects sequences with indeterminations in the middle'
		default_value = 'true'
		params.check_param(errors,'middle_indetermination_rejects','String',default_value,comment)
    
    return errors
  end
  
  
end
