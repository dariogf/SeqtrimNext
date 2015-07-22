#!/usr/bin/env ruby

#########################################
# Author:: Almudena Bocinos Rioboo
# This class provided the methods to read the parameter's file and to create the structure where will be storaged the param's name and the param's numeric-value
 #########################################
class ScanForRestrSite
  
  #Creates the structure and start the reading of parameter's file
  def initialize(sequence,rest)    
    @seq_fasta=sequence 
    @rest=rest      
    puts "#{@seq_fasta}  , #{@rest}"  
    res = execute
    

    res.each do |e| 
        puts "#{e.join(',')}"
    end
    
  # selects from res,the max good hit  
    puts "--- MAX: --- "
    
    max = res.max{|e1,e2| e1[1]<=> e2[1]}
                      
    puts max.join(' ; ')                    
                                             
  # checks if the max one has the size of restriction with a margen error
    margen = (@rest.size <= 4)? 0 : 1;  # <- don't change       
    if ((max[1] !=  @rest.size) && (max[1] != @rest.size-margen)) 
      puts "-the max good hit hasn't the size minimum: #{@rest.size} or #{@rest.size-margen} "
      max=[]
    end
    
    
    
    #read_file(path)   
  end
            
  
  
  def execute    
    r=[]
                              # 
                              # for (my $p=0; $p < $sL-$srfL; $p++){
                              #     $os = $ns = $xs = 0;
                              #     for ( my $i=0; $i < $srfL; $i++ ) {
                              #         my $c  = substr($s, $i+$p, 1);  # ver si decrementar antes pos
                              #         my $cc = substr($restrSite, $i, 1);
                              #         if ($c eq $cc) {
                              #             ++$os;
                              #         } elsif ($c eq "N"){
                              #             ++$ns;
                              #         } else {
                              #             ++$xs;
                              #         }
                              #     }
                              #     $r[$p] = [$p, $os, $ns, $xs];
                              #         print "$p, $os, $ns, $xs\n";
                              # }                     
    for p in 0..@seq_fasta.size-@rest.size 
        os = 0; 
        ns = 0; 
        xs = 0;                    
        puts "-------[#{p}]-#{@seq_fasta[p,@seq_fasta.size-p]}  , #{@rest}"  
        
       i=0
      @rest.each_char do |cc|
         c = @seq_fasta[i+p].chr
         puts "(#{c}==#{cc})=>#{c==cc}"
        if (c == cc)
          os += 1
        elsif (c == 'N')
          ns += 1
        else     
          xs += 1
        end
        i+=1     
        
      end
      r[p]=[p,os,ns,xs]
       puts r[p].join(',')
    end     
    return r
  end
  
  # Reads param's file
  def read_file(path_fichero)
    File.open(path_fichero).each_line do |line| 
           
      line.chomp! # delete end of line      
      
      if !line.empty?
        if !(line =~ /^#/)   # if line is not a comment
          # extract the parameter's name in params[0] and the parameter's value in params[1]
          params = line.split(/\s*=\s*/)
          
          # storage in the hash the pair key/value, in our case will be name/numeric-value , 
          # that are save in params[0] and params[1],  respectively
          @h[params[0]] = params[1]
          
          $LOG.debug "read: #{params[1]}"
        end # end if comentario
      end #end if line
    end #end each
    $LOG.info "File Params have been readed"

  end# end def

  #  Prints the pair name/numeric-value for every parameter  
  def print_parameters()
    @h.each do |clave, valor|
      
      $LOG.debug  "The Parameter #{clave} have the value " +valor.to_s
    end
  end
  
  # Return the parameter's list in an array
  def get_param(param)
    #$LOG.debug "Get Param:  #{@h[param]}"
    return @h[param]
  end
  
  def set_param(param,value)
    @h[param] = value
  end
  
  #attr_accessor :h  # to accede to the atribute 'h' from out of this class
  
  # Returns true if exists the parameter and nil if don't
  def exists?(param_name)
    return !@h[param_name].nil?
  end
  
end      
scan = ScanForRestrSite.new("AaaaACGTACGT", "AGTAC")
# scan = ScanForRestrSite.new("AaaaACGTAeCGT", "AGTAC")

