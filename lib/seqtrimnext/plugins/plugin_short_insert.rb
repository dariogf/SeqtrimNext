require "plugin"

########################################################
# Author: Almudena Bocinos Rioboo                      
# 
# Defines the main methods that are necessary to execute PluginShortInserted                                                     
# Inherit: Plugin
########################################################

class PluginShortInsert < Plugin 
  
  def cut_by(items,sub_inserts) 
       
     
    delete=false 
    # puts " eee1 #{sub_inserts.inspect} item #{items.inspect}"
    # puts " eee1 #{sub_inserts.join('-')}"   
    
    items.each  do |item|  
      sub_inserts.each do |sub_i|
      
        if ((item.start_pos<=sub_i[0]) && (item.end_pos>=sub_i[1])) 
          # if not exists any subinsert
          delete=true
            
        elsif ((item.end_pos>=sub_i[0]) && (item.end_pos+1<=sub_i[1]))
          # if exists an subinsert  between the item one and the end of subinsert  
          
          sub_inserts.push [item.end_pos+1,sub_i[1]]        # mark subinsert after the item
          
          delete=true 
          # puts " !!!! 1 #{sub_inserts.inspect}" 
          if ((item.start_pos-1>=sub_i[0]))
            # if exists an subinsert  between the start of the subinsert and the item   
            sub_inserts.push [sub_i[0],item.start_pos-1]    # mark subinsert before the item
            delete=true

            # puts " !!!! 2-1 #{sub_inserts.inspect}" 
          end 
          
        elsif ((item.start_pos-1>=sub_i[0]) && (item.start_pos<=sub_i[1]))
            # if exists an subinsert  between the start of the subinsert and the item   
            sub_inserts.push [sub_i[0],item.start_pos-1,]   # mark subinsert before the item 
            delete=true

            # puts " !!!! 2-2 #{sub_inserts.inspect}" 
          
            
        end  
        
        
        # sub_inserts.delete [sub_i[0],sub_i[1]] and delete=false  and puts " DELETEEE ___________  #{delete}" if delete
        if delete  
          sub_inserts.delete [sub_i[0],sub_i[1]] 
          delete=false  
          # puts " DELETEEE ___________  #{delete} #{[sub_i[0] , sub_i[1]] }"     
        end
        # puts " eee2 #{sub_inserts.join(',')}" 
               
                                                                       
      end #each sub_insert
    end #each low_qual
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
  
  def exec_seq(seq,blast_query)
    $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: checking if insert of sequence has enought size" 
    # puts "inserto #{seq.insert_start}, #{seq.insert_end} size #{seq.seq_fasta.size}" 
    
    if (seq.seq_fasta.size > 0)
      
      # para acciones que no tienen activado el cortar, se las corta aquí
      sub_inserts=[]   
      sub_inserts.push [ seq.insert_start, seq.insert_end]
      low_quals=seq.get_actions(ActionLowQuality)
      # puts "low qual size #{low_quals.size}"
      cut_by(low_quals,sub_inserts)  
      
      # puts '?' + sub_inserts.join('?')
    
      if sub_inserts.empty? 
        p_beg,p_end = 0,-1  # position from an empty insert 
        
      else
        sub_inserts=select_the_best(sub_inserts)
    
        #vemos el tamaño del inserto actual
        # puts " antes current_insert #{seq.seq_fasta.length}"
        # p_beg,p_end = seq.current_insert  
    
        # p_beg,p_end = seq.insert_bounds  
        p_beg,p_end = sub_inserts[0][0],sub_inserts[0][1]  # insert positions
        # puts " p_beg p_end #{p_beg} #{p_end}"
    
    
        # puts " despues current_insert #{p_beg} #{p_end}"
        size_min_insert = @params.get_param('min_insert_size_trimmed').to_i 
      end    
      
    else 
      p_beg,p_end = 0,-1  # position from an empty insert 
      # puts " p_beg p_end #{p_beg} #{p_end} size=  #{p_end-p_beg+1}" 
    end

    # puts "INSERTO:"+seq.seq_fasta
    actions=[]  
    # puts " in PLUGIN SHORT INSERT previous to add action #{p_beg} #{p_end}"
    if p_end-p_beg+1 <= 0
         type = "ActionEmptyInsert"
         # puts " in PLUGIN EMPTY previous to add action #{p_beg} #{p_end}"
         # a = seq.add_action(p_beg,p_end,type)  
         a=seq.new_action(0,0,type) 
         actions.push a 
         add_stats('short_inserts',0)
         # puts "1 p_beg p_end #{p_beg} #{p_end}"
         
         seq.seq_rejected=true 
         seq.seq_rejected_by_message='empty insert'        
    elsif ((p_end-p_beg+1)<size_min_insert)
         type = "ActionShortInsert"
         a_beg,a_end = p_beg-seq.insert_start, p_end-seq.insert_start
       
         # puts " in PLUGIN SHORT previous to add action"
         # a = seq.add_action(p_beg,p_end,type)  
         a=seq.new_action(a_beg,a_end,type) 
         actions.push a                     
         add_stats('short_inserts',a_end-a_beg+1)
       
         # puts "2 p_beg p_end #{p_beg} #{p_end}" 
         
         seq.seq_rejected=true 
         seq.seq_rejected_by_message='short insert' 
    else
      type= "ActionInsert" 
    
      # a=seq.add_action(p_beg,p_end,type)
      a_beg,a_end = sub_inserts[0][0]-seq.insert_start, sub_inserts[0][1]-seq.insert_start
      a=seq.new_action(a_beg,a_end,type)      
      actions.push a                     
      
      add_stats('inserts',a_end-a_beg+1)
    
      # puts "3 p_beg p_end #{p_beg} #{p_end}"  
    end

    seq.add_actions(actions)  
    
          
  end
 

  #Begins the plugin1's execution to warn if the inserted is so short 
   def execute_no_cut_quality(seq)  
     $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: checking if insert of sequence has enought size" 

    

     #vemos el tamaño del inserto actual
     # puts " antes current_insert #{seq.seq_fasta.length}"
     # p_beg,p_end = seq.current_insert 
     p_beg,p_end = seq.insert_bounds
     # puts " despues current_insert #{p_beg} #{p_end}"
     size_min_insert = @params.get_param('min_insert_size_trimmed').to_i  

     # puts "INSERTO:"+seq.seq_fasta
     actions=[]  
     # puts " in PLUGIN SHORT INSERT previous to add action #{p_beg} #{p_end}"
     if p_end-p_beg+1 <= 0
          type = "ActionEmptyInsert"
          # puts " in PLUGIN EMPTY previous to add action #{p_beg} #{p_end}"
          # a = seq.add_action(p_beg,p_end,type)  
          a=seq.new_action(0,0,type) 
          actions.push a

     elsif ((p_end-p_beg+1)<size_min_insert)
          type = "ActionShortInsert"
          # puts " in PLUGIN SHORT previous to add action"
          # a = seq.add_action(p_beg,p_end,type)  
          a=seq.new_action(0,p_end-p_beg,type) 

          actions.push a
     else
       type= "ActionInsert" 

       # a=seq.add_action(p_beg,p_end,type)
       a=seq.new_action(0,p_end-p_beg,type)  
       actions.push a
     end

     seq.add_actions(actions)

   end

  #Returns an array with the errors due to parameters are missing 
  def self.check_params(params)
    errors=[]  
    
    self.check_param(errors,params,'min_insert_size_trimmed','Integer')
    
    # if !params.exists?('genus')
    #   errors.push " The param genus doesn't exist "
    # end
    
    # if !params.exists?('p2')
    #   errors.push " The param p2 doesn't exist"
    # end
    
    return errors
  end
  
  
end
