require "plugin"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginLinker                                                     
# Inherit: Plugin
########################################################

class PluginExtractInserts < Plugin   
  
  #------------------------------------------------------
  # check if part of a vector is in a linker
  #------------------------------------------------------
  def part_left_overlap?(r1_start,r1_end,r2_start,r2_end)
    
     
     
     return ((r1_start<r2_start) and (r1_end<=r2_end)  and (r1_end>=r2_start) )  #overlap on the left of r2
             
  end   
  
  def part_right_overlap?(r1_start,r1_end,r2_start,r2_end)
   
     
     
     return ((r1_end>r2_end) and (r1_start<=r2_end)  and (r1_start>=r2_start) )    #overlap on the right of r2
  end                                                                                                           
  
  
  # crea una action insert controlado si el inserto es corto o no y  actualiza las stats según sea inserto izquierdo o derecho
  def add_action_inserts(insert,linker,actions,seq) 

    insert_size = insert[1]-insert[0]+1
    
    min_insert_size = @params.get_param('min_insert_size_paired').to_i
  
    if  (insert_size >= min_insert_size)
        if (insert[0]<linker.start_pos) #insert is on the left from the linker 

          add_stats('left_insert_size',insert_size)
        elsif (insert[0]>linker.end_pos)   #insert is on the right from the linker 

          add_stats('right_insert_size',insert_size)         
        end  
        
        a = seq.new_action(insert[0]-seq.insert_start,insert[1]-seq.insert_start,"ActionInsert") # adds the ActionInsert to the sequence 
        actions.push a 

    else
       
      if (insert[0]<linker.start_pos) #insert is on the left from the linker 
        # @stats[:short_left_insert_size]={insert_size => 1}  
        add_stats('short_left_insert_size',insert_size)
      elsif (insert[0]>linker.end_pos)   #insert is on the right from the linker 
        # @stats[:short_right_insert_size]={insert_size => 1} 
        add_stats('short_right_insert_size',insert_size)
      end
      
      
      #create an ActionShortInsert before the ActionLinker

      # adds the ActionInsert to the sequence 
      a = seq.new_action(insert[0]-seq.insert_start,insert[1]-seq.insert_start,"ActionShortInsert") # adds the ActionInsert to the sequence 
      
   
      actions.push a  
        
     end      
   
   
       
     
    
  end
  
  #-------------------------------------------------------------------------
  #It's created an ActionInsert or ActionShortInsert before the ActionLinker 
  #Used: in class PluginLinker and PluginMid
  #-------------------------------------------------------------------------
  def add_action_before_linker(overlap,actions,seq)
                                                  
    # puts "INSERT1: [#{seq.insert_start},#{overlap.start_pos}]"
                                                          
    insert_size = overlap.start_pos - seq.insert_start
    
    min_insert_size = @params.get_param('min_insert_size_trimmed').to_i  
    
    # puts "INSERT1: [#{overlap.start_pos},#{seq.insert_start} #{seq.insert_end}   seqsize #{seq.seq_fasta.size} insert_size #{insert_size} #{min_insert_size}]" 
        
                                                   
  
    if ((overlap.start_pos>seq.insert_start) && (insert_size >= min_insert_size))#if overlap's positions are right    
        #It's created an ActionInsert or ActionShortInsert before the Actionoverlap    
        # a = seq.new_action(seq.insert_start_last,overlap.start_pos-1-seq.insert_start,"ActionInsert") # adds the ActionInsert to the sequence 
        a = seq.new_action(0,overlap.start_pos-1-seq.insert_start,"ActionInsert") # adds the ActionInsert to the sequence 
       
        actions.push a 
        # puts " 1---------- Inserto antes del linker en pos #{a.start_pos} #{a.end_pos}"
     elsif (overlap.start_pos>seq.insert_start)   #if overlap's positions are right and insert's size is short   
       # puts " 2---------- #{seq.insert_start},#{overlap.start_pos}-1-#{seq.insert_start}" 
       
          
       #It's created an ActionShortInsert before the ActionLinker
       # a = seq.new_action(seq.insert_start_last-seq.insert_start,overlap.start_pos-1-seq.insert_start,"ActionShortInsert") # adds the ActionInsert to the sequence 
       a = seq.new_action(0,overlap.start_pos-1-seq.insert_start,"ActionShortInsert") # adds the ActionInsert to the sequence 
       
       actions.push a  
       # puts " 2---------- Inserto corto antes del linker en pos #{a.start_pos} #{a.end_pos}" 
       
        
     end      
   
   
    @stats[:insert_size_left]={insert_size => 1}
    
  end
  
  #-------------------------------------------------------------------------
  #It's created an ActionInsert or ActionShortInsert after the ActionLinker 
  #-------------------------------------------------------------------------
  def add_action_after_linker(overlap,actions,seq) 
                                                   
    # puts "INSERT2: [#{overlap.end_pos},#{seq.insert_end}]"
              
    insert_size = seq.insert_end-overlap.end_pos
    
    min_insert_size = @params.get_param('min_insert_size_trimmed').to_i

    # puts "INSERT_SIZE2 #{insert_size} > #{min_insert_size}"         
    
    # puts "INSERT2: [#{overlap.end_pos},#{seq.insert_start} #{seq.insert_end} #{seq.seq_fasta.size} #{seq.seq_fasta_orig.size}]"  

    if ((overlap.end_pos-seq.insert_start < seq.seq_fasta_orig.size-1) && (insert_size>=min_insert_size) )  #if overlap's positions are left 
      #It's created an ActionInsert after the Actionoverlap
      a = seq.new_action(overlap.end_pos-seq.insert_start+1,seq.seq_fasta.size-1,"ActionInsert") # adds the ActionInsert to the sequence  
      # puts " new after action #{overlap.end_pos} - #{seq.insert_start}" 
      # puts " 1---new insert despues del linker #{a.start_pos} #{a.end_pos} " 
      

      actions.push a
        
    elsif (overlap.end_pos-seq.insert_start<seq.seq_fasta_orig.size-1)   #if overlap's positions are right and insert's size is short 
      #It's created an ActionInsert after the ActionLinker
      a = seq.new_action(overlap.end_pos-seq.insert_start+1,seq.seq_fasta.size-1,"ActionShortInsert") # adds the ActionInsert to the sequence
      
      # puts " new after action #{overlap.end_pos} - #{seq.insert_start} +1" 
      # puts "2---new insert short despues del linker #{a.start_pos} #{a.end_pos} "
      actions.push a 
    end    
    # puts "#{a.start_pos} #{a.end_pos}" if !a.nil?
    @stats[:insert_size_right]={insert_size => 1}   
    
  end
        
  
  
  
  


  
  def split_by(actions,sub_inserts) 
       
    delete=false 
    
    # puts " split #{sub_inserts.each{|i| i.join(',')}}"
    if !sub_inserts.empty?
      actions.each  do |action|  
        sub_inserts.reverse_each do |sub_i|
          # puts "A: [#{action.start_pos},#{action.end_pos}] cuts [#{sub_i[0]},#{sub_i[1]}] "
          if ((action.start_pos<=sub_i[0]) && (action.end_pos>=sub_i[1])) 
            # if not exists any subinsert
            delete=true
            
          elsif ((action.end_pos>=sub_i[0]) && (action.end_pos+1<=sub_i[1]))
            # if exists an subinsert  between the action one and the end of subinsert  
          
            sub_inserts.push [action.end_pos+1,sub_i[1]]        # mark subinsert after the action
          
            delete=true 
            # puts " !!!! 1" 
            if ((action.start_pos-1>=sub_i[0]))
              # if exists an subinsert  between the start of the subinsert and the action   
              sub_inserts.push [sub_i[0],action.start_pos-1]    # mark subinsert before the action
              delete=true

              # puts " !!!! 2-1" 
            end 
          
          elsif ((action.start_pos-1>=sub_i[0]) && (action.start_pos<=sub_i[1]))
              # if exists an subinsert  between the start of the subinsert and the action   
              sub_inserts.push [sub_i[0],action.start_pos-1,]   # mark subinsert before the action 
              delete=true

              # puts " !!!! 2-2" 
          
          
          end  
        
        
          # sub_inserts.delete [sub_i[0],sub_i[1]] and delete=false  and puts " DELETEEE ___________  #{delete}" if delete
          if delete  
            sub_inserts.delete [sub_i[0],sub_i[1]] 
            delete=false  
            # puts " DELETEEE ___________  #{delete} #{[sub_i[0] , sub_i[1]] }"     
          end
          # puts " eee #{sub_inserts.join(',')}" 
               
                                                                       
        end #each sub_insert
      end #each action
    end
  end
                                                 
  #select the best subinsert, when there is not a linker
  def select_the_best(sub_inserts)   
    
    insert_size = 0
       
    insert = nil
       
    sub_inserts.each do |sub_i|
      
      if (insert_size<(sub_i[1]-sub_i[0]+1))
        insert_size = (sub_i[1]-sub_i[0]+1) 
        insert=sub_i 
      end       
      
    end    
    
    sub_inserts=[]
    sub_inserts.push insert  if !insert.nil?
        
    # puts " subinsert #{sub_inserts.join(' ')}" 
    
    return sub_inserts
  end

#select the best subinsert when there is a linker 
  def select_the_best_with_linker(sub_inserts,linker)   
    
    left_insert_size = 0
    right_insert_size = 0 
    
    left_insert = nil
    right_insert = nil
   
    sub_inserts.each do |sub_i|
      #puts "*SBI: "+sub_i.join(',')
      if (sub_i[0]<linker.start_pos)   #if the subinsert is on the left from the linker 
        if (left_insert_size<(sub_i[1]-sub_i[0]+1))
          left_insert_size = (sub_i[1]-sub_i[0]+1) 
          left_insert=sub_i
          # puts " left"
        end       
        
      elsif (sub_i[0]>linker.end_pos)   #if the subinsert is on the right from the linker
        if (right_insert_size<(sub_i[1]-sub_i[0]+1))
          right_insert_size = (sub_i[1]-sub_i[0]+1) 
          right_insert=sub_i 
        end
          # puts " right"
      end
    end    
    # puts " left #{left_insert} #{left_insert_size} right #{right_insert} #{right_insert_size}"
    sub_inserts=[]
    sub_inserts.push left_insert  if !left_insert.nil?
    sub_inserts.push right_insert if !right_insert.nil?     
    # puts " subinsert #{sub_inserts.join(' ')}" 
    #puts "SELECTED SUBINSERTS"
#    sub_inserts.each do |sub_i|
#      puts "*SBI: "+sub_i.join(',')
#    end
#    
    return sub_inserts
  end
  
  def exec_seq(seq,blast_query)
     $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: extract inserts"    
          
     # puts "INSERTO ANTES LINKER INSERT:"+seq.seq_fasta

     #look for ActionLinker into the sequence's actions
     linkers=seq.get_actions(ActionLinker)       
     #look for ActionVectors into the sequence's actions
     vectors=seq.get_actions(ActionVectors)   
     #look for ActionLowQuality into the sequence's actions
     low_quals=seq.get_actions(ActionLowQuality)
     
     insert_size=0
     actions=[] 
     sub_inserts=[]
     
     if (linkers.count==1) #linker found   
        linker=linkers[0]
        
        # get left insert
        if linker.start_pos>seq.insert_start
          sub_inserts.push [ seq.insert_start,linker.start_pos-1 ]  
        end
        
				#get right insert
        if linker.end_pos<seq.insert_end
          sub_inserts.push [ linker.end_pos+1, seq.insert_end]
        end
        # puts '1ST SUBS:'
        # puts sub_inserts.join("\n")
				#split sub_inserts by vectors
        split_by(vectors,sub_inserts)
        # puts 'SUBS:'
        # puts sub_inserts.join("\n")
        
        #sub_inserts=select_the_best_with_linker(sub_inserts,linker) if not sub_inserts.empty?   
        
        # split by low qual actions
        split_by(low_quals,sub_inserts)
        # puts 'SUBS:'
        # puts sub_inserts.join("\n")
        sub_inserts=select_the_best_with_linker(sub_inserts,linker)  if not sub_inserts.empty?   
        
        if sub_inserts.empty?
          # if is an empty insert
          a=seq.new_action(0,0,'ActionEmptyInsert') 
          seq.seq_rejected=true 
          seq.seq_rejected_by_message='empty insert'
          actions.push a
        end
        
        sub_inserts.each do |sub_i| 
          add_action_inserts(sub_i,linker,actions,seq)  # ponerlo también abajo para que controle si la accion es de inserto corto o no
        end
        
      
     else # no linker found => add whole insert

       sub_inserts.push [ seq.insert_start, seq.insert_end ]
       
       split_by(vectors,sub_inserts)

       #sub_inserts=select_the_best(sub_inserts) if not sub_inserts.empty?   
       
       split_by(low_quals,sub_inserts)
       
       sub_inserts=select_the_best(sub_inserts) if not sub_inserts.empty?

       # ordena los subinsertos por tamaño 
       # sub_inserts.sort!{|i,j| j[1]-j[0]<=>i[1]-i[0]}
       
       if sub_inserts.empty?
         found_insert_size = 0  # position from an empty insert
         
         a=seq.new_action(0,0,'ActionEmptyInsert') # refactorizando codigo
         seq.seq_rejected=true
         seq.seq_rejected_by_message='empty insert'
       else
         found_insert_size =(sub_inserts[0][1]-sub_inserts[0][0]+1)
       end 

  
       if (found_insert_size >= (@params.get_param('min_insert_size_trimmed').to_i))     
         add_stats('insert_size',found_insert_size)
         a = seq.new_action(sub_inserts[0][0]-seq.insert_start, sub_inserts[0][1]-seq.insert_start,"ActionInsert") # adds the ActionInsert to the sequence before adding the actionMid   
       elsif (found_insert_size!=0)  # if is a short insert
         add_stats('short_insert_size',found_insert_size)                                                                                                
         a = seq.new_action(sub_inserts[0][0]-seq.insert_start, sub_inserts[0][1]-seq.insert_start,"ActionShortInsert") # adds the ActionInsert to the sequence before adding the actionMid   
         seq.seq_rejected=true 
         seq.seq_rejected_by_message='short insert'
       end
       actions.push a   
     end
     
     seq.add_actions(actions)    
                   
                   
     # find inserts to see if it is necessary to reject it
      
     if ! seq.seq_rejected
	     inserts=seq.get_actions(ActionInsert)
	     if inserts.empty? 
		     seq.seq_rejected=true 
		  
		     if seq.get_actions(ActionShortInsert).empty?
		       seq.seq_rejected_by_message='empty insert'
		     else
			     seq.seq_rejected_by_message='short insert'
		     end
	     end     
     end
  end
  
  #Returns an array with the errors due to parameters are missing 
  
  def self.check_params(params)
    errors=[]
    
    # self.check_param(errors,params,'min_insert_size_trimmed','Integer')
    
    return errors
  end
  
  def self.plot_setup(stats_value,stats_name,x,y,init_stats,plot)

    # puts "============== #{stats_name}"
    
    # puts stats_name
    case stats_name
      
    when 'insert_size'
      plot.x_label= "Length"
      plot.y_label= "Count"
      plot.x_range="[0:#{init_stats['biggest_sequence_size'].to_i}]"
      # plot.x_range="[0:200]"
      
      plot.add_x(x)
      plot.add_y(y)
      
      plot.do_graph
      
      return true
    else
      return false
    end
    
  end
  

  
end
