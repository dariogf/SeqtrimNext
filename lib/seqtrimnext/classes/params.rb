#########################################
# Author:: Almudena Bocinos Rioboo
# This class provided the methods to read the parameter's file and to create the structure where will be storaged the param's name and the param's numeric-value
#########################################
require 'scbi_fasta'

class Params

  #Creates the structure and start the reading of parameter's file
  def initialize(path)
    @params = {}
    @comments = {}
    # @param_order={}
    @mids = {}
    @ab_adapters={}
    @adapters={}
    @linkers = {}
    @clusters = {}

    @plugin_comments = {}

    read_file(path)
  end

  # Reads param's file
  def read_file(path_file)

    if path_file && File.exists?(path_file)
      comments= []
      File.open(path_file).each_line do |line|
        line.chomp! # delete end of line

        if !line.empty?
          if !(line =~ /^\s*#/)   # if line is not a comment
            # extract the parameter's name in params[0] and the parameter's value in params[1]
            params = line.split(/\s*=\s*/)

            # store in the hash the pair key/value, in our case will be name/numeric-value ,
            # that are save in params[0] and params[1],  respectively
            if (!params[0].nil?) && (!params[1].nil?)
              set_param(params[0].strip,params[1].strip,comments)
              comments=[]
            end

            #$LOG.debug "read: #{params[1]}"
          else
            comments << line.gsub(/^\s*#/,'')
          end # end if comentario
        end #end if line
      end #end each
      if @params.empty?
        puts "INVALID PARAMETER FILE: #{path_file}. No parameters defined"
        exit
      end

    end
  end# end def

  def load_db_fastas(input_paths)

    res={}

    if (!input_paths.nil?) & (input_paths!='')
      # remove quotes
      paths=input_paths.gsub(/\A['"]+|['"]+\Z/, "")

      # split paths by spaces
      # puts "PATHS:"
      # puts paths.split(' ')
      paths.split(' ').each do |path_file|

        if File.exists?(path_file)
          ff = FastaFile.new(path_file)
          ff.each {|n,f|
            res[n]=f
          }

          ff.close
        end
      end

    end

    # puts "LOADED_DB #{paths}:"
    # res.each do |k,v|
    #   puts k
    # end

    return res
  end

  # Load mid's file
  def load_mids(path_file)
    @mids=load_db_fastas(path_file)
    # puts @mids
  end

  # Load ab_adapters file
  def load_ab_adapters(path_file)
    @ab_adapters=load_db_fastas(path_file)
    # puts @ab_adapters
  end

  # load normal adapters
  def load_adapters(path_file)
    @adapters=load_db_fastas(path_file)
  end


  # Load mid's file
  def load_linkers(path_file)
    @linkers=load_db_fastas(path_file)
    # puts @linkers
  end

  def load_repeated_seqs(file_path)
    @clusters={}

    if File.exists?(file_path)
      # File.open(ARGV[0]).each_line do |line|
      $LOG.debug("Repeated file path:"+file_path)
      File.open(file_path).each_line do |line|
        #puts line,line[0]
        # en ruby19 line[0] da el caracter, no el chr
        #if (line[0]!=62) && (line[0]!=48)
        # if (line[0]!='>'[0]) && (line[0]!='0'[0])

        # line doesn't finish in *
        if (line[0]!='>'[0]) && (!(line =~ /\*$/))

          #puts line
          # puts line,line[0]
          if line =~ />([^\.]+)\.\.\.\s/
            #puts 'ok'
            # puts $1
            @clusters[$1]=1
          end
        end
      end
      $LOG.info("Repeated sequence count: #{@clusters.count}")
    else
      $LOG.error("Clustering file's doesn't exists: #{@clusters.count}")
    end


  end

  def repeated_seq?(name)
    return !@clusters[name].nil?
  end

  # Reads param's file
  def save_file(path_file)

    f=File.open(path_file,'w')
    @plugin_comments.keys.sort.reverse.each do |plugin_name|
      f.puts "#"*50
      f.puts "# " + plugin_name
      f.puts "#"*50
      f.puts ''

      @plugin_comments[plugin_name].keys.each do |param|
        comment=get_comment(plugin_name,param)
        if !comment.nil? && !comment.empty? && comment!=''
          f.puts comment.map{|c| '# '+c if c!=''}
        end
        f.puts ''
        f.puts "#{param} = #{@params[param]}"
        f.puts ''
      end
    end
    f.close

  end# end def

  #  Prints the pair name/numeric-value for every parameter
  def print_parameters()
    @params.each do |clave, valor|
      #$LOG.debug  "The Parameter #{clave} have the value " +valor.to_s
      puts "#{clave} = #{valor} "
    end
  end

  # Return the parameter's list in an array
  def get_param(param)
    #$LOG.debug "Get Param:  #{@params[param]}"
    return @params[param]
  end

  def get_fasta(list,name,type)
    res = list[name]

    if res.nil?
      $LOG.error("Error. The #{type}: #{name} was not correctly loaded")
      raise "Error. The #{type}: #{name} was not found in loaded #{name}s: #{list.map{|k,v| k}}."
    end

    return res
  end

  # Return the mid's size of param
  def get_mid(mid)
    # return @mids[mid]
    return get_fasta(@mids,mid,"mid")
  end

  # Return the linker of param
  def get_linker(linker)
    # return @linkers[linker]
    return get_fasta(@linkers,linker,"linker")
  end

  # Return the ab of param
  def get_ab_adapter(adapter)
    # return @ab_adapters[adapter]
    return get_fasta(@ab_adapters,adapter,"ab_adapter")
  end

  def get_adapter(adapter)
    # return @adapters[adapter]
    return get_fasta(@adapters,adapter,"adapter")
  end


  def get_plugin
    plugin='General'
    # puts caller(2)[1]
    at = caller(2)[1]
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ at
      file = Regexp.last_match[1]
      line = Regexp.last_match[2].to_i
      method = Regexp.last_match[3]
      plugin=File.basename(file,File.extname(file))

    end
    
  end
  
  def set_param(param,value,comment = nil)
     plugin=get_plugin

     @params[param] = value

     if get_comment(plugin,param).nil?
       set_comment(plugin,param,comment)
     end


   end
  
  def get_comment(plugin,param)
     res = nil
     if @plugin_comments[plugin]
       res =@plugin_comments[plugin][param]
     end
     return res
   end
  
  
  def set_comment(plugin,param,comment)
     if !comment.is_a?(Array) && !comment.nil?
       comment=comment.split("\n").compact.map{|l| l.strip}
     end

     if @plugin_comments[plugin].nil?
       @plugin_comments[plugin]={}
     end

     old_comment=''
     # remove from other plugins
     @plugin_comments.each do |plugin_name,comments|
       if comments.keys.include?(param) && plugin_name!=plugin
         old_comment=comments[param]
         comments.delete(param)
       end
     end

     if comment.nil?
       comment=old_comment
     end

     # @comments[param]=(comment || [''])
     @plugin_comments[plugin][param]=(comment || [''])
     # puts @plugin_comments.keys.to_json

     # remove empty comments

     @plugin_comments.reverse_each do |plugin_name,comments|
       if comments.empty?
         @plugin_comments.delete(plugin_name)
       end
     end

   end

  
  def set_mid(param,value)
    @mids[param] = value
  end
  
  # Returns true if exists the parameter and nil if don't
  def exists?(param_name)
     return !@params[param_name].nil?
   end
 
  def check_plugin_list_param(errors,param_name)
     # get plugin list
     pl_list=get_param(param_name)

     # puts pl_list,param_name
     list=pl_list.split(',')

     list.map!{|e| e.strip}

     # puts "Lista:",list.join(',')


     # always the pluginExtractInserts at the end
     list.delete('PluginExtractInserts')
     list << 'PluginExtractInserts'

     set_param(param_name,list.join(','))
     # if !list.include?('PluginExtractInserts')
     #   raise "PluginExtractInserts do not exists"
     #
     # end



   end

  # def split_databases(db_param_name)
  def check_db_param(errors,db_param_name)
     if !get_param(db_param_name).empty?
       # expand database paths
       dbs= get_param(db_param_name).gsub('"','').split(/\s+/)
       # puts "ALGO"*20
       # puts "INPUT DATABASES:\n"+dbs.join(',')

       procesed_dbs=[]
       #
       # TODO - chequear aqui que la db no esta vacia y que esta formateada.
       dbs.reverse_each {|db_p|
         db=File.expand_path(db_p)

         if !File.exists?(db)
           path=File.join($FORMATTED_DB_PATH,db_p)
         else
           path=db
         end


         if Dir.glob(path+'*.n*').entries.empty?
           puts "DB file #{path} not formatted"

           if File.writable_real?(path)
             cmd = "makeblastdb -in #{path} -parse_seqids -dbtype nucl"
             system(cmd)
           else
             raise "Can't format database. We don't have write permissions in: #{path}"
           end
         end

         procesed_dbs << path

         if !File.exists?(path)
           raise "DB File #{path} does not exists"
           # exit
         end
       }

       db_paths = '"'+procesed_dbs.join(' ')+'"'

       set_param(db_param_name,db_paths)

       puts "USED DATABASES\n"+db_paths
     end
   end
  
  
  def self.generate_sample_params

                         filename = 'sample_params.txt'
                         x=1
                         while File.exists?(filename)
                           filename = "sample_params#{x}.txt"
                           x+=1
                         end

                         f=File.open(filename,'w')
                         f.puts "SAMPLE_PARAMS"
                         f.close

                         puts "Sample params file generated: #{filename}"

                       end
  
  def check_param(errors,param,param_class,default_value=nil, comment=nil)

                         if !exists?(param)
                           if default_value.nil? #|| (default_value.is_a?(String) && default_value.empty?)
                             errors.push "The param #{param} is required and no default value is available"
                           else
                             set_param(param,default_value,comment)
                           end
                         end

                         s = get_param(param)


                         set_comment(get_plugin,param,comment)

                         # check_class=Object.const_get(param_class)
                         begin

                           case param_class
                           when 'Integer'
                             r = Integer(s)
                           when 'Float'
                             r = Float(s)
                           when 'String'
                             r = String(s)
                           when 'DB'
                             # it is a string
                             r = String(s)
                             # and must be a valid db

                             r = check_db_param(errors,param)

                           when 'PluginList'
                             r=String(s)
                             r= check_plugin_list_param(errors,param)
                           end

                         rescue Exception => e
                           message="Current value is ##{s}#. "
                           if param_class=='DB'
                             message += e.message
                           end

                           errors.push "Param #{param} is not a valid #{param_class}. #{message}"
                         end
                         # end

                       end

end
