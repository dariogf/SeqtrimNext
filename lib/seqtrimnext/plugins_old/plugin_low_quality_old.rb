require "plugin"  

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginLowQuality. See the main method called execute.

#                                                     
# Inherit: Plugin
########################################################

class PluginLowQuality < Plugin   
  
    
      
      def create_sum_window(qual,ini,index_window_end)
      
        # puts "--------index w #{index_window_end}" 
        sum=[] 
        i=ini  
        # puts "#{i} #{index_window_end}"
        while (i<=index_window_end) # initialize sum                                  
          sum[i]=0 
          i += 1
        end
        # puts " contenido de sum" + sum.join.to_s  + " i index_window_end  window #{i} #{index_window_end} #{@window}" 
      
        i=ini
        while (i<ini+@window)
      
          sum[ini] += qual[i] 
          i+=1
        end                                           
      
      
        i=ini+1 
      
        while (i<=index_window_end)            
      
          sum[i]=sum[i-1]-qual[i-1]+qual[i+@window-1]
          i+=1
      
        end   
      
        # puts '2____' + sum.join(',') + 'pos sum' + ini.to_s    
      
        return sum 
      
      end   
      
      def find_bounds_high_quality(sum,ini,index_window_end) 
      
        new_start = -1
        new_end = -1
        
      # puts " ini #{ini} iwe #{index_window_end}"
      # puts "ini #{ini} index_window_end #{index_window_end} sum[ini] #{sum[ini]} cut_off #{@cut_off} suma #{sum.size} " 
       if (ini>index_window_end) 
           temp_start= ini
           # new_start, new_end = temp_start, index_window_end 
           new_end = index_window_end # para que no crea que no hay alta calidad, sino que hemos sobrepasado el indice final de la ventana
             # new_start, new_end = index_window_end, index_window_end 
       end   
      # puts " temp_start #{temp_start}" if (ini>index_window_end)
      temp_start=((ini<=index_window_end) && (sum[ini]>=@cut_off))? ini : -1    
      
        i=ini+1
        while (i<=index_window_end)
          if (sum[i]>=@cut_off)  
            if (temp_start<0)
               temp_start=i  #just in! 
               # puts "just in ---- #{sum[i]}>= cut off #{@cut_off} pos #{temp_start}"   
            end
      
          else 
              # puts "sum #{sum[i]} < cut off "
              if(temp_start>=0)              #just out!   
                # puts "update #{sum[i]}< cut off #{@cut_off} pos #{i}.if #{i-1} - #{temp_start} > #{new_end} - #{new_start}"
                if (((i-1-temp_start)>=(new_end-new_start)))   
                  new_start,new_end=temp_start,i-1 
                  # puts "just out ---- new start,new_end = #{temp_start}, #{i-1}  index_window_end = #{index_window_end}"   
                end
                temp_start= -1 
              end
          end
          i+=1  
      
      
        end 
        # puts "4 temp_start #{temp_start} new_start #{new_start} new-end #{new_end}"  
      
        if (temp_start != -1)   # finished while ok           
          # puts "4 #{index_window_end} - #{temp_start} > #{new_end} - #{new_start}"
            if ((index_window_end- temp_start) >= (new_end-new_start)) #put the end of the window at the end of sequence
                new_start, new_end = temp_start, index_window_end     #-1
            end
        end  
      
        # puts "5 temp_start #{temp_start} new_start #{new_start} new-end #{new_end}"   
        
        # puts  " newstart  #{new_start} newend #{new_end}" 
       
        return new_start,new_end 
       
      
      end  
      
      def cut_fine_bounds_short(qual,new_start,new_end)
      
          i=0                    
          # puts " qual[new_start+i] new_start #{new_start} i #{i} = #{new_start+i} qual.size #{qual.size}"
          while (i<@window)
            if (qual[new_start+i]>=@low)
              break
            end    
            i+=1
          end  
          new_start +=i 
          # puts "#{new_start} ***********"
      
          i=@window -1
          while (i>=0)  
            if (qual[new_end+i]>=@low)    
              break            
            end
            i-=1            
          end     
          new_end += i
          # puts "6a new_start #{new_start} new-end #{new_end}"     
          
           # puts " #{new_start} #{new_end} .o.o.o.o.o.o.o.o2 short"    
          return new_start, new_end  
      
      end  
      
      
      # cuts fine the high quality bounds
      def cut_fine_bounds(qual,new_start,new_end)   
        # puts "  ççççççççççççççç #{new_start+@window} >= #{new_end} " 
        # puts " #{new_start} #{new_end} .o.o.o.o.o.o.o.o1"
        # cut it fine
      
         one_ok = 0         
      
          i=@window-1
          # puts " qual[new_start+i] new_start #{new_start} i #{i} = #{new_start+i} qual.size #{qual.size}"
          while (i>=0) 
              if (qual[new_start+i] < @low) 
                  break if one_ok
              else 
                  one_ok = 1
              end    
              i-=1
          end
          new_start += i+1
          oneOk = 0  
          i=0
          while (i<@window) 
              if (qual[new_end+i] < @low) 
                  break if oneOk
              else 
                  oneOk = 1
              end  
              i+=1
          end
          new_end += i-1 
          # puts "6b  new_start #{new_start} new-end #{new_end}"  
      
        # puts " #{new_start} #{new_end} .o.o.o.o.o.o.o.o2"
        return new_start, new_end
      
      end
      
      def find_high_quality(qual,ini=0)  
      
        # puts qual.class.to_s + qual.size.to_s + 'size,' + @window.to_s + ' window, '+ qual.join(',')  + 'size' + qual.size.to_s
        
        update=false
        # if @window>qual.length-ini     #search in the last window although has a low size
        #     @window=qual.length-ini   
        #      # puts ' UPDATE WINDOW  Y CUT OFF ' + @window.to_s
        #      @cut_off=@window*@low   
        #      update=true
        #   end          
                   
        if (ini==0 or update)
          #index_window_start = ini
          @index_window_end = qual.size- @window #don't sub 1, or will lost the last nucleotide of the sequence -1;
          #TODO En seqtrim de Juan iwe, que en nuestro seqtrim se llama index_window_end, está perdiendo 2 nucleótidos de la última ventana calculada 
      
      
          @sum = create_sum_window(qual,ini,@index_window_end) 
          # puts "SUMA #{@sum.join(' ')}"   
        end              
              
        new_start, new_end = find_bounds_high_quality(@sum,ini,@index_window_end) 
        # puts " #{new_start} #{new_end} .o.o.o.o.o.o.o.o1"
      
        if (new_start>=0)
          if (new_start+@window >= new_end)
             # puts "cfs"     
            new_start, new_end = cut_fine_bounds_short(qual,new_start,new_end)
            # puts "cfs"
      
          else  
            # puts "cf"
            new_start, new_end = cut_fine_bounds(qual,new_start,new_end) 
            # puts "cf"
          end 
        end 
        
         # puts " #{new_start} #{new_end} .o.o.o.o.o.o.o.o2" 
      
        return new_start,new_end #+1
      
      
      end
      
      
      def add_action_before_high_qual(p_begin,p_end,actions,seq,start)
      
        action_size = p_begin-1
        if action_size>=(@window/2)  
      
      
          # puts "action_SIZE1 #{action_size} > #{@window/2}"
      
          if ( (p_begin>0) && (action_size>0) )  #if there is action before the high qual part 
            # it's created an action before of the high quality part
            a = seq.new_action(start ,p_begin-1,"ActionLowQuality") # adds the ActionInsert to the sequence before adding the actionMid
            # puts " new low qual start: #{start}  = #{a.start_pos} end: #{p_begin} -1 = #{a.end_pos}"
            actions.push a   
          end 
        end             
      end  
      
      def add_action_after_high_qual(p_begin,p_end,actions,seq)
      
        action_size = seq.insert_end-p_end
        if action_size>=(@window/2)
      
      
           # puts "action_SIZE2 #{action_size} > #{@window/2}"
      
           if ((p_end<seq.seq_fasta.size-1) && (action_size>0) )  #if there is action before the high qual part 
             # it's created an action before of the high quality part
             a = seq.new_action(p_end-seq.insert_start+1,seq.seq_fasta.size-1,"ActionLowQuality") # adds the ActionInsert to the sequence before adding the actionMid
      
             actions.push a   
           end 
         end 
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
       $LOG.error " Quality File haven't been provided. It's impossible to execute " + self.class.to_s     
     elsif (seq.seq_qual.size>0)
       $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: checking low quality of the sequence"    

       @low=@params.get_param('min_quality').to_i

       if @params.get_param('window_width').to_i>seq.seq_fasta.length   
         @window=seq.seq_fasta.length   
       
       else 
         @window=@params.get_param('window_width').to_i
       end 
       @cut_off=@window*@low   
                                           
       type='ActionLowQuality' 
       low_qual=0
       actions=[] 
       
       p_begin,p_end =0,-1 # positions from high quality bounds    
                                
       
       
       while ((p_begin>=0)  && (p_end + 1 < seq.seq_qual.size) ) 
         
         
         p_begin_old,p_end_old= p_begin, p_end
         p_begin,p_end = find_high_quality(seq.seq_qual,p_end+1)  
         
         if ((p_begin>0) && (p_begin-p_end_old-1>=@window/2)) #if we have found the high quality part, and  the low quality part has enough size 
            # it's created an action before of the high quality part 
            add_action_before_high_qual(p_begin,p_end,actions,seq,p_end_old+1) 

            # puts "low1 ini fin  #{p_end_old+1} #{p_begin-1} = #{p_begin-1-p_end_old-1+1}"     
            low_qual = p_begin-1-p_end_old-1 + 1 
            
            add_stats('low_qual',low_qual)
            # @stats[:low_qual]={low_qual => 1} 
             
         end
         
         # puts "-----ññññ----- high quality  #{p_begin}   #{p_end}+#{seq.insert_start} seq size #{seq.seq_fasta.size}"

       end
        
       # puts "high [#{p_begin}, #{p_end}] old [#{p_begin_old}, #{p_end_old}] size #{seq.seq_qual.size}"   
       if ((p_begin>=0) && (p_end+1<seq.seq_qual.size))  #if we have found the high quality part 
          
          # it's created an action after of the high quality part     
          add_action_after_high_qual(p_begin,p_end,actions,seq) 
          # puts "low2 ini fin #{p_end+1} #{seq.seq_fasta.size-1}  = #{seq.seq_fasta.size-1-p_end-1+1}"
          low_qual = seq.seq_fasta.size-1 - p_end-seq.insert_start-1 + 1
          # if @stats[:low_qual][low_qual].nil?
          #              @stats[:low_qual][low_qual] = 0
          #           end
          #           @stats[:low_qual][low_qual] += 1  
          add_stats('low_qual',low_qual) 
          # @stats[:low_qual]={low_qual => 1}    
       end                                     

       # puts "-----ññññ----- high quality  #{p_begin}   #{p_end}"  
   
       
       if p_end<0 and p_end_old #add action low qual to all the part      
         a = seq.new_action(p_end_old+1 ,seq.seq_fasta.size-1,"ActionLowQuality") # adds the ActionInsert to the sequence before adding the actionMid
         # puts "new low qual start: #{p_end_old+1} end: #{seq.seq_fasta.size-1} = #{seq.seq_fasta.size-1 - p_end_old-1 + 1}" 
         low_qual = seq.seq_fasta.size-1 - p_end_old-1 + 1 
         
          # if @stats[:low_qual][low_qual].nil?
          #             @stats[:low_qual][low_qual] = 0
          #          end
          #          @stats[:low_qual][low_qual] += 1   
         add_stats('low_qual',low_qual) 
         # @stats[:low_qual]={'low_qual' => 1} 
          
         actions.push a
       end
       
       # puts "------- ADDING ACTIONs LOW QUAL #{actions.size}"    
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
		
   	comment='Quality window for scanning low quality segments'
		default_value = 15
		params.check_param(errors,'window_width','Integer',default_value,comment)
   

    
    return errors
  end
  
  
  private :find_high_quality
  
end
