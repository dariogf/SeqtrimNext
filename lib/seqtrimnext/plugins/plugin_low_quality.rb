require "plugin"  

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginLowQuality. See the main method called execute.

#                                                     
# Inherit: Plugin
########################################################

class PluginLowQuality < Plugin   
  
    

  def next_low_qual_region(quals,from_pos,min_value,max_good_quals=2)

     rstart=nil
     rend=nil

     i=from_pos

     good_q=0

     # skip good values
     while (i< quals.length) && (quals[i]>=min_value)
       i +=1 
     end 

     # now we have found a bad quality, or end of sequence
     if i < quals.length
       rstart=i
       len=0

        # puts "   - [#{rstart},#{len}]"

       # continue growing while region of lowqual until more than 2 bases of good qual are found
       begin
         q=quals[i]

         if q<min_value
           len += 1
           # puts "BAD #{q}<#{min_value}"
           len += good_q
           good_q=0
         else
           good_q+=1
         end
          # puts "#{q} - q[#{rstart},#{rend}], #{good_q}"     

         i+=1
       end while (i < quals.length) && (good_q <= max_good_quals)

       rend = rstart + len -1
       # puts "#{q} - q[#{rstart},#{rend}], #{good_q}"     
     end

     return [rstart,rend]
  end

  # A region is valid if it starts in 0, ends in seq.length or is big enought
  def valid_low_qual_region?(quals,rstart,rend,min_region_size)
    # puts [rstart,rend,0,quals.length,(rend-rstart+1)].join(';')
    # res =((rstart==0) || (rend==quals.length-1) || ((rend-rstart+1)>=min_region_size))
    # if res
    #    puts "VALID"
    # end
    return ((rstart==0) || (rend==quals.length-1) || ((rend-rstart+1)>=min_region_size))
  end


  def get_low_qual_regions(quals,min_value, min_region_size,max_good_quals=2)

    # the initial region is the whole array
    left=0
    right=quals.length-1
    # puts quals.map{|e| ("%2d" % e.to_s)}.join(' ')

    # puts "[#{left},#{right}]"

    i = 0

    from_pos=0
    regions =[]

    # get all new regions
    begin
      rstart, rend = next_low_qual_region(quals,from_pos,min_value,max_good_quals)
      if !rstart.nil?
        from_pos= rend+1

        if valid_low_qual_region?(quals,rstart,rend,min_region_size)
          regions << [rstart,rend]
        end
      end
    end while !rstart.nil?

    return regions  

  end
      

                                                                                   


  
  ######################################################################
  #---------------------------------------------------------------------
 
  # Begins the plugin1's execution whit the sequence "seq"
  # Creates an action by each subsequence with low quality to eliminate it 
  # A subsequence has low quality if (the add of all its qualitis < subsequence_size*20)  
  # Creates the qualities windows from the sequence, looks for the subsequence with high quality 
  # and mark, with an action, the before part to the High Quality Subsequence like a low quality part 
  # Finally  mark, with an action, the after part to the High Quality Subsequence like a low quality part 
  #----------------------------------------------------------------- 
   
  def exec_seq(seq,blast_query)

     if ((self.class.to_s=='PluginLowQuality') && seq.seq_qual.nil? ) 
       $LOG.debug " Quality File haven't been provided. It's impossible to execute " + self.class.to_s     
     elsif ((seq.seq_qual.size>0) && (@params.get_param('use_qual').to_s=='true'))
          
          $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: checking low quality of the sequence"
          
          min_quality=@params.get_param('min_quality').to_i
          min_length_inside_seq=@params.get_param('min_length_inside_seq').to_i
          max_consecutive_good_bases=@params.get_param('max_consecutive_good_bases').to_i
          
          type='ActionLowQuality'
          actions=[]
          
          regions=get_low_qual_regions(seq.seq_qual,min_quality,min_length_inside_seq,max_consecutive_good_bases)
          
          regions.each do |r|
            low_qual_size=r.last-r.first+1
            
            # puts "(#{low_qual_size}) = [#{r.first},#{r.last}]: #{a[r.first..r.last].map{|e| ("%2d" % e.to_s)}.join(' ')}"
           
           
           add_stats('low_qual',low_qual_size)
           
           
           # create action
           a = seq.new_action(r.first,r.last,type) # adds the correspondent action to the sequence
           actions.push a
           
           
           
          end

          # add quals
          seq.add_actions(actions)
     end       

   end 
   
  #-----------------------------------------------------------------
  
  
  ######################################################################
  #---------------------------------------------------------------------

  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params) 
    
    errors=[]
    
   	comment='Minimum quality value for every nucleotide'
		default_value = 20
		params.check_param(errors,'min_quality','Integer',default_value,comment)
		
    
	  #comment='Quality window for scanning low quality segments'
		#default_value = 15
		#params.check_param(errors,'window_width','Integer',default_value,comment)
   
    
	  comment='Minimum length of a bad quality segment inside the sequence'
		default_value = 8
		params.check_param(errors,'min_length_inside_seq','Integer',default_value,comment)
   
    
	  comment='Maximum consecutive good-quality bases between two bad quality regions'
		default_value = 2
		params.check_param(errors,'max_consecutive_good_bases','Integer',default_value,comment)
    
    return errors
  end
  
end
