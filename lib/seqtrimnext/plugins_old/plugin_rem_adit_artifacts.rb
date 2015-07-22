require "plugin"


########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginRemAditArtifacts

#                                                     
# Inherit: Plugin
########################################################

class PluginRemAditArtifacts < Plugin
  
  
  
  def exec_seq(seq,blast_query)
       
    $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: removing artifacts into the sequence"    
    seq2 = seq.seq_fasta    
    first = 0
    last = seq2.size-1    
    old_first=first
    old_last=last
      

    while (seq2 =~ /^(GCGGGG|CCCCGC)/i)
      first += 6
      seq2.slice!(0..5)
    end
    
    
    while (seq2 =~ /(GCGGGG|CCCCGC)$/i)
      last -= 6
      seq2.slice!(seq2.size-1-5..seq2.size-1)
      
    end
   
    
    #is_forward, is_cDNA, 
    #TrimExtremeNXs(first,last)
    is_forward = @params.get_param('is_forward')=='true'
    is_cDNA = @params.get_param('is_cDNA')=='true'
     
    previous_first,previous_last =0,0
    
    until ((previous_first == first) && (previous_last == last))
      previous_first,previous_last = first, last      
    
      if (is_cDNA)
        if (is_forward)
           
          nTs = 0
          nTs = $1.length if (seq2 =~ /^(T+)/i) 
          
          if (nTs > 3)
            seq2.slice!(0..nTs -1)            
            first += nTs #-1
           
          end
          
          nAs = 0
          nAs = $1.length if (seq2 =~ /(A+)$/i)
        
          if (nAs > 3)            
            seq2.slice!(seq2.size - nAs..seq2.size - 1)
            last -= nAs
            
          end
        else #si es backward
           
          nTs = 0
          nTs = $1.length if (seq2 =~ /(T+)$/i) 
          
          if (nTs > 3)            
            seq2.slice!(seq2.size-nTs..seq2.size-1)
            last -= nTs
            
          end
    
          nAs = 0
          nAs = $1.length if (seq2 =~ /^(A+)/i)
          
          if (nAs > 3)            
            seq2.slice!(0..nAs -1)
            first += nAs
          
          end
        end    
      end
    end 
    
      
    if (((first>=0) && (first>old_first)) || ((last>=0) && (last<old_last)))
      type='ActionRemAditArtifacts'           
      actions = []          
      # seq.add_action(first,last,type)  
      a=seq.new_action(first,last,type) 
      actions.push a
      seq.add_actions(actions)    
    end
   
    
  end
  ######################################################################
  #---------------------------------------------------------------------
  def execute_old(seq)
    seq2 = seq.seq_fasta   
    #seq2 = 'dGCGGGG' 
    first = 0
    last = seq2.size-1    
    old_first=first
    old_last=last
      
    # puts '1 '+seq2
    # puts 'POS '+first.to_s
    # puts 'POS '+last.to_s
    while (seq2 =~ /^(GCGGGG|CCCCGC)/i)
      first += 6
      seq2.slice!(0..5)
     # puts '2 '+seq2
     # already = true
    end
    
    
    while (seq2 =~ /(GCGGGG|CCCCGC)$/i)
      last -= 6
      seq2.slice!(seq2.size-1-5..seq2.size-1)
      # puts '3 '+seq2
     # already = true
    end
   
    
    #is_forward, is_cDNA, 
    #TrimExtremeNXs(first,last)
    is_forward = @params.get_param('is_forward')
    is_cDNA = @params.get_param('is_cDNA')
     # puts '4 '+seq2
     previous_first,previous_last =0,0
    
    until ((previous_first == first) && (previous_last == last))
      previous_first,previous_last = first, last
      # puts 'POS5-F '+first.to_s
      # puts 'POS5-L '+last.to_s
    
      if (is_cDNA)
        if (is_forward)
           # puts '5 '+seq2
          nTs = 0
          nTs = $1.length if (seq2 =~ /^(T+)/i) 
          if (nTs > 3)
            seq2.slice!(0..nTs -1)
             # puts '6 '+seq2
            first += nTs #-1
            # puts 'POS6-F '+first.to_s
          end
          nAs = 0
          nAs = $1.length if (seq2 =~ /(A+)$/i)
          # puts '6-7 '+seq2 + nAs.to_s
          if (nAs > 3)
            # puts '7 '+seq2
            seq2.slice!(seq2.size - nAs..seq2.size - 1)
            last -= nAs#seq2.size-nAs-2
            # puts 'POS7-L '+last.to_s
          end
        else #si es backward
           # puts '5b '+seq2
          nTs = 0
          nTs = $1.length if (seq2 =~ /(T+)$/i) 
          if (nTs > 3)
             # puts '6b '+seq2
            seq2.slice!(seq2.size-nTs..seq2.size-1)
            last -= nTs#seq2.size-nTs -2
            # puts 'POS6b-L '+last.to_s
          end
    
          nAs = 0
          nAs = $1.length if (seq2 =~ /^(A+)/i) 
          if (nAs > 3)
             # puts '7b '+seq2
            seq2.slice!(0..nAs -1)
            first += nAs#nAs -1
            # puts 'POS7b-f '+first.to_s
          end
        end    
      end
    end 
    
       #first -= 1 if (old_first!= first) 
        #last += 1 if (old_last!= last)
    
    # puts 'POS7-8 '+first.to_s
    # puts 'POS7-8 '+last.to_s
      
    if (((first>=0) && (first>old_first)) || ((last>=0) && (last<old_last)))
      type='ActionRemAditArtifacts'
            
       # puts '8 '+seq2
      seq.add_action(first,last,type)    
    end
     # puts '9 '+seq2
    
  end
  
 

  ######################################################################
  #---------------------------------------------------------------------

  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]
    
    
    
#    if !params.exists?('ta')
#      errors.push " The param <ta> doesn't exist"
#    end
    
#    if !params.exists?('poly_at_length')
#      errors.push " The param <poly_at_length> doesn't exist"
#    end
    

    
    return errors
  end
  
  
  
  
  
  
end
