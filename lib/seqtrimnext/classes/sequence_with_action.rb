
require "action_manager.rb"
require "sequence"
require 'term/ansicolor'
include Term::ANSIColor

######################################
# Author:: Almudena Bocinos Rioboo
# This class create the structure to storage the actions associated to a sequence. 
# It allows to add action, and to write at file the actions for every sequence
# Inherit:: Sequence
######################################

class SequenceWithAction < Sequence    
  SHOW_QUAL = false
  SHOW_FINAL_INSERTS=true

  attr_accessor :actions,:seq_fasta_orig, :seq_qual_orig ,:insert_start , :insert_end, :stats , :insert_start_last , :insert_end_last, :order_in_tuple, :tuple_id, :tuple_size
    
  # Creates an instance with the structure to storage the actions associated to a sequence  
  def initialize(seq_name,seq_fasta,seq_qual, seq_comment = '')
    super

    @actions = []
    @seq_fasta_orig = seq_fasta
    @seq_fasta = seq_fasta
    
    @seq_qual_orig = seq_qual
    @seq_qual = seq_qual     
    
    @insert_start = 0
    @insert_end = seq_fasta.length-1 
    
    @stats={}
    @comments=[]
    
    @file_tags=[]
    
    # for paired ends
    @order_in_tuple=0
    @tuple_id=0
    @tuple_size=0
    @file_tag_tuple_priority=0
    
  end
  
  def add_comment(comment)
    @comments.push comment
  end
  
  def get_comment_line
    return ([@seq_rejected_by_message]+@comments).compact.join(';')
  end
  
  # add a file tag to sequence
  def add_file_tag(tag_level, tag_value, tag_type, priority=0)
    @file_tags<< {:level => tag_level, :name => tag_value, :type=> tag_type}
    @file_tag_tuple_priority=priority
  end
  
  # join file tags into a path
  def get_file_tag_path
    levels=@file_tags.map{|e| e[:level]}.uniq

    dirpath = []
    levels.sort.each do |level|
      # select names from all that are not files
      level_path = @file_tags.select{|e| ((e[:level]==level) && (e[:type]!=:file))}.map{|tag| tag[:name]}
      dirpath << level_path.join('_') if !level_path.empty?
    end
    
    filepath = []
    levels.sort.each do |level|
      # select names from all that are not files
      level_path = @file_tags.select{|e| ((e[:level]==level) && (e[:type]!=:dir))}.map{|tag| tag[:name]}
      filepath << level_path.join('_') if !level_path.empty?
    end
    
    
    filename=filepath.join('_')
    dirname=File.join(dirpath)
    
    
    # puts "#{dirname}, #{filename}"
    
    return [dirname,filename,@file_tag_tuple_priority]
    
  end
  
  # Adds a new action to the sequence  
    def add_action(a)
      $LOG.debug("Adding action #{a.type} to #{seq_name}")
            
      @actions.push a
      
      a.apply_to(self)
      
      return a
      
    end        
    
    # Adds a new action to the sequence  
    def new_action(start_pos,end_pos,action_type)
      
      a = ActionManager.new_action(start_pos,end_pos,action_type)
      
      return a
      
    end        
                  
  
  # def left_action(seq_fasta,start_pos,end_pos)
  #    return ((start_pos - 0 ) < (seq_fasta.length - end_pos))
  #  end
  #  
  #  def right_action(seq_fasta,start_pos,end_pos)
  #    return !left_action(seq_fasta,start_pos,end_pos)
  #  end 
  
  # Adds a set of actions to the sequence, update the positon of the cut sequence. # 
  # Version with the parameters left_action and rigth action #
  
  # TODO - Nuevo algoritmo de corte de seqs. 
  # 1 - Ordenar seqs con cut=true en izq y der y por posición de ends o begs
  # 2 - Obtener izq.ends.max y der.begs.min
  # 3 - El corte lo definen esos min y max
  
  def add_actions(actions)
                
    if !actions.empty?             
       start_pos=0
       end_pos = 0
       cut = false              

       max_end_pos = 0 
       
           
       
       p_beg = @insert_start
       p_end = @seq_fasta.length-1+@insert_start   
       # p_end = @seq_fasta.length-1   
       # puts "ADDING ACTIONS"
       # puts "=" * 50
       # puts 'actions ' + actions.inspect                               
       # para cada accion ordenada por start_pos
       actions.sort{|e,f| e.start_pos<=>f.start_pos}.each do |action| 
         # puts ' current ' + action.inspect
         # puts " UUUUUUUUUU1 "
         # puts "vect in pos #{action.start_pos} #{action.end_pos}" if (action.type=='ActionVectors') 
         # puts " UUUUUUUUUU2 " 
                        
         # puts "ADD ACTION:",action.to_json
                         
         # añadir el inicio del inserto si es necesario         
         if action.start_pos !=0 or action.end_pos != 0
            action.start_pos+=@insert_start    
            action.end_pos+=@insert_start            
         end       
         
         # guardar accion  
         a = add_action(action)
         
         start_pos= a.start_pos                     
         end_pos=a.end_pos             
                                    
                       
         # si hay que cortar y es accion izquierda
         # if (a.cut && ( left_action(@seq_fasta,start_pos-p_beg,end_pos) ||   # action is left in insert
         if (a.cut && a.left_action?(@seq_fasta.length))
         # if (a.cut && ( a.left_action==true || 
         #                       ( a.right_action==false && (left_action(@seq_fasta,start_pos-p_beg,end_pos-p_beg) ||   # action is left in insert
         #                        (start_pos==p_beg)) )))     # action is right in insert but it's continous to the before action  
         #              
             # puts "in seq w action left act  #{start_pos} #{end_pos} pbeg #{p_beg} p_end #{p_end}"                                                                        
              # puts "Cut left: #{a.inspect}"
             if (end_pos+1) > p_beg
               p_beg=end_pos+1
             end
             a.left_action=true
             cut=true     
             # puts "in seq w action left act  #{start_pos} #{end_pos} pbeg #{p_beg} p_end #{p_end}"                                                                        
             
          # elsif (a.cut && right_action(@seq_fasta,start_pos-p_beg,end_pos)) # action is rigth  in insert
         elsif (a.cut && a.right_action?(@seq_fasta.length))
           # puts "Cut right: #{a.inspect}"
          # elsif (a.cut && (a.right_action==true || right_action(@seq_fasta,start_pos-p_beg,end_pos-p_beg))) # action is rigth  in insert 
             # puts "in seq w action right act  #{start_pos} #{end_pos} pbeg #{p_beg} p_end #{p_end}"   
             if (start_pos-1) < p_end
               p_end = start_pos-1   
             end
             a.right_action=true
             cut=true  
             # puts "in seq w action right act  #{start_pos} #{end_pos} pbeg #{p_beg} p_end #{p_end}"  
         elsif !a.cut
             # puts "NO cut action"
             if a.right_action?(@seq_fasta.length)
               a.right_action=true
             else
               a.left_action = true
             end

         end  
          
         # puts "p_beg: #{p_beg} , p_end: #{p_end}"
        
      end
      
 
      if cut then 
               
        @seq_fasta = @seq_fasta_orig[p_beg..p_end] 
        # puts @seq_fasta
        @seq_qual = @seq_qual_orig[p_beg..p_end] if !@seq_qual_orig.nil?
                    
        # puts "in seq w action1 #{@insert_start} #{@insert_end}"
        @insert_start = p_beg
        size_cut_right = @insert_end - p_end
        @insert_end -= size_cut_right
        # puts "in seq w action2 #{@insert_start} #{@insert_end}" 
        
        
      end    
     end
   end   
                                                                                  
  
  # Adds a set of actions to the sequence, update the positon of the cut sequence. # 
  # Version without the parameters left_action and rigth action #
  
  def add_actions_no_left_rigth_parameters(actions)
                
    if !actions.empty?
       start_pos=0
       end_pos = 0
       cut = false              

       max_end_pos = 0 
       
           
       
       p_beg = @insert_start
       p_end = @seq_fasta.length-1+@insert_start   
       # p_end = @seq_fasta.length-1   
             
       # puts 'actions ' + actions.inspect                               
       # para cada accion ordenada por start_pos
       actions.sort!{|e,f| e.start_pos<=>f.start_pos}.each do |action| 
         # puts ' current ' + action.inspect
         # puts " UUUUUUUUUU1 "
         # puts "vect in pos #{action.start_pos} #{action.end_pos}" if (action.type=='ActionVectors') 
         # puts " UUUUUUUUUU2 " 
                        
         # puts "ADD ACTION:",action.to_json
                         
         # añadir el inicio del inserto si es necesario         
         if action.start_pos !=0 or action.end_pos != 0
            action.start_pos+=@insert_start    
            action.end_pos+=@insert_start            
         end       
         
         # guardar accion  
         a = add_action(action)
         
         start_pos= a.start_pos                     
         end_pos=a.end_pos             
                                    
                        
         # si hay que cortar y es accion izquierda
         # if (a.cut && ( left_action(@seq_fasta,start_pos-p_beg,end_pos) ||   # action is left in insert
         if (a.cut && ( left_action(@seq_fasta,start_pos-p_beg,end_pos-p_beg) ||   # action is left in insert
                       (start_pos==p_beg)) )     # action is right in insert but it's continous to the before action  
             
             puts "in seq w action left act  #{start_pos} #{end_pos} pbeg #{p_beg} p_end #{p_end}"                                                                        
             
             p_beg=end_pos+1
             cut=true     
             a.left_action=true
             # puts "in seq w action left act  #{start_pos} #{end_pos} pbeg #{p_beg} p_end #{p_end}"                                                                        
             
          # elsif (a.cut && right_action(@seq_fasta,start_pos-p_beg,end_pos)) # action is rigth  in insert 
          elsif (a.cut && right_action(@seq_fasta,start_pos-p_beg,end_pos-p_beg)) # action is rigth  in insert 
             puts "in seq w action right act  #{start_pos} #{end_pos} pbeg #{p_beg} p_end #{p_end}"  
             p_end = start_pos-1   
             a.right_action=true
             cut=true  
             # puts "in seq w action right act  #{start_pos} #{end_pos} pbeg #{p_beg} p_end #{p_end}"  
          elsif !a.cut
            puts "NO cut action"
            if right_action(@seq_fasta,start_pos-p_beg,end_pos-p_beg)
              a.right_action=true
            end
            
          end  
          
 
        
      end
      
 
      if cut then 
               
        @seq_fasta = @seq_fasta_orig[p_beg..p_end] 
        @seq_qual = @seq_qual_orig[p_beg..p_end] if !@seq_qual_orig.nil?
                    
        # puts "in seq w action1 #{@insert_start} #{@insert_end}"
        @insert_start = p_beg
        size_cut_right = @insert_end - p_end
        @insert_end -= size_cut_right   
        # puts "in seq w action2 #{@insert_start} #{@insert_end}" 
        
 
        
      end    
     end
   end  
   
  	# check if range defined by q_beg and q_end is inside some action of the type indicated by action_type  
  def range_inside_action_type?(q_beg,q_end,action_type)
  		res = false

		action_list = get_actions(action_type)
		
		action_list.each do |action|
			
			if action.contains_action?(q_beg+@insert_start,q_end+@insert_start,10)
				res = true
				break
			end
		end
  		
  		return res
  
  end

  
  
  # Prints a sequence with its actions to a file
  def to_text
    
      output_res=[]
      
      if @seq_rejected
        output_res<< "[#{@tuple_id},#{@order_in_tuple}] Sequence #{seq_name} had the next actions: ".bold.underline + " REJECTED:  #{@seq_rejected_by_message}".red    
        # puts  @seq_name.bold + bold + ' REJECTED BECAUSE ' +@seq_rejected_by_message.bold if @seq_rejected 
      else
        output_res<< "[#{@tuple_id},#{@order_in_tuple}] Sequence #{seq_name} had the next actions: ".bold.underline  
        
      end
      
      n=1
      withMessage = ["ActionIsContaminated","ActionVectors","ActionBadAdapter","ActionLeftAdapter","ActionRightAdapter"]  
      color = red
      
      @actions.sort!{|e,f| e.start_pos<=>f.start_pos}.each do |a|     
        a_type=a.action_type
        color = a.apply_decoration(" EXAMPLE ") 
        color2 =a.apply_decoration(" #{a_type.center(8)} ") 
           
        reversed_str = ''    
        
        if a.reversed
          reversed_str = "   REVERSED  ".bold 
        end
        
        output_res<< " [#{n}] ".bold + color2+ " #{a.title} ".ljust(24).reset  +  " [ " + " #{a.start_pos+1}".center(6) + " , " + "#{a.end_pos+1}".center(6) + " ]" +  clear.to_s + "#{a.message}".rjust(a.message.size+8) + reversed_str
        
        n +=1   
      end
      
      pos = 0
      res = '' 
      
      @seq_fasta_orig.each_char do |c|
        
        @actions.each do |a|
          c= a.decorate(c,pos) 
          
        end 
        
        res += c
        
        pos += 1
      end       
              
      output_res<< res
      
      if SHOW_QUAL and @seq_qual_orig
         res = '' 
         pos=0               
         output_res<< ''
        @seq_fasta_orig.each_char do |c2|
          c=@seq_qual_orig[pos].to_s+' '
          @actions.each do |a|
            c= a.decorate(c,pos) 

          end 
          res += c
          pos += 1
        end
               
        output_res<< res
      end
      
      if SHOW_FINAL_INSERTS      		 
         output_res<<  "INSERT ==>"+get_inserts.join("\nINSERT ==>")
         output_res<< "="*80
      end
      # puts  @seq_name.bold + bold + ' rejected because ' +@seq_rejected_by_message.bold if @seq_rejected                 

      return output_res
  end 
  
  def to_text_seq_fasta
     return " "*@insert_start +@seq_fasta
  end
  
  # Saves a sequence with its actions to a file
  def save_to_file
    File.open("results/#{seq_name}"+".txt", 'w') { |file|
     
      n=1
      
      @actions.each do |a|
        file.puts a.description
        n +=1   
      end
    } 
    
  end
  
  def action_right(a,p_beg,p_end) 
    
      # $LOG.debug " is right action" if ((a.start_pos-p_beg)>(p_end-a.end_pos-1))   
      # $LOG.debug " is left action " if !((a.start_pos-p_beg)>(p_end-a.end_pos-1))   
      return ((a.start_pos-p_beg)>(p_end-a.end_pos-1))
    
  end
  
  
  # def is_first_action(p_beg,p_end,seq_end)    
  #    return ((p_beg==0) && (p_end==seq_end))
  # end  
      
  #Receive a type of action. Be carefull, type is not a string .
  #Return an array of actions of this type            
  def get_actions(type=nil)
     res = []
               
     @actions.each do |a|
        if a.is_a?(type) or type.nil?
          res.push a
        end
     end
     
     return res
  end
  
  
   
  
  def get_inserts
     
    inserts = get_actions(ActionInsert)
    
    res =[]         
    inserts.each do |insert|
      res.push @seq_fasta_orig[insert.start_pos..insert.end_pos]
    end
  
    return res 
  
  end
  
  def get_qual_inserts
     
    inserts = get_actions(ActionInsert)
    
    res =[]
    
    if @seq_qual_orig
      inserts.each do |insert|
        res.push @seq_qual_orig[insert.start_pos..insert.end_pos]
      end
    end
    
    return res 
  
  end
  
  def insert_bounds
    return [@insert_start,@insert_end]
  end

  def to_json
     s={}
     s[:seq_name]=@seq_name
     s[:seq_fasta]=@seq_fasta_orig
     s[:seq_qual]=''
     if @seq_qual_orig
       s[:seq_qual]=@seq_qual_orig.join(' ')
     end
     s[:rejected]=@rejected
     

     s[:fasta_inserts]= get_inserts
     s[:qual_inserts]=get_qual_inserts.map { |e| e.join(' ') }
     s[:actions]=[]
     
     @actions.each { |a| s[:actions].push a.to_hash }
     # puts "YAML",s.to_yaml
     return JSON.pretty_generate(s)
  end
  # private :to_text
  
end
