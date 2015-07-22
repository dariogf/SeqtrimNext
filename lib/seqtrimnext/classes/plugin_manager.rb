#########################################
# Author:: Almudena Bocinos Rioboo
# This class provided the methods to manage the execution of the plugins
 #########################################

require 'json'

require 'sequence_with_action'
require 'sequence_group'

class PluginManager   
  attr_accessor :plugin_names
  
  #Storages the necessary plugins specified in 'plugin_list' and start the loading of plugins
  def initialize(plugin_list,params)
    @plugin_names = plugin_list.strip.split(',').map{|p| p.strip}.reject{|p| ['',nil].include?(p)}
    @params = params
    
    # puts plugin_list
    load_plugins_from_files     
    
  end
  
  # Receives the plugin's list , and create an instance from its respective class (it's that have the same name)
  def execute_plugins(running_seqs)
    # $LOG.info " Begin process: Execute plugins "
    
    if !@plugin_names.empty?
      
      # keeps a list of rejected sequences
      
      rejected_seqs = []

      @plugin_names.each do |plugin_name|
        
        
        # remove rejected or empty seqs from execution list
        running_seqs.reverse_each do |seq|
          if seq.seq_rejected || seq.seq_fasta.empty?
            # remove from running
            running_seqs.delete(seq)
            # save in rejecteds
            rejected_seqs.push seq
          end
        end
        
        if running_seqs.empty?
          break
        end
        
        # Creates an instance of the respective plugin stored in "plugin_name",and asociate it to the sequence 'seq'
        plugin_class = Object.const_get(plugin_name)

        plugin_execution=plugin_class.new(running_seqs,@params)

        running_seqs.stats[plugin_name] = plugin_execution.stats
        
        # puts running_seqs.stats.to_json
        plugin_execution=nil


      end #end  each
      
      running_seqs.add(rejected_seqs)

      
    else
      
      raise "Plugin list not found"
    end #end  if lista-param
  end
  
  # Checks if the parameters are right for all plugins's execution. Finally return true if all is right or false if isn't 
  def check_plugins_params(params)
    res = true
    
    if !@plugin_names.empty?
      #$LOG.debug " Check params values #{plugin_list} "

      @plugin_names.each do |plugin_name|
        
        #Call to the respective plugin storaged in 'plugin_name'
        plugin_class = Object.const_get(plugin_name)
        # DONE - chequear si es un plugin de verdad u otra clase
        # puts plugin_class,plugin_class.ancestors.map {|e| puts e,e.class}
        
        if plugin_class.ancestors.include?(Plugin)
          errors=plugin_class.check_params(params)          
        else
          errors= [plugin_name + ' is not a valid plugin']
        end

        if !errors.empty?
          $LOG.error plugin_name+ ' found following errors:'
          errors.each do |error|
            $LOG.error '   -' + error
            res = false
          end #end each
        end #end if

      end #end  each
    else
      $LOG.error "No plugin list provided"
      res = false
    end #end  if plugin-list
    
    return res
  end
  
  
  # Iterates by the files from the folder 'plugins', and load it
  def load_plugins_from_files
           
    # DONE - CARGAR los plugins que hay en @plugin_names en vez de todos 
    
    # the plugin_name changes to file using plugin_name.decamelize    
    @plugin_names.each do |plugin_name|
      plugin_file = plugin_name.decamelize
      require plugin_file
    end
    
  end # end  def
    
  
  # Iterates by the files from the folder 'plugins', and load it
  def load_plugins_from_files_old
           
    # DONE - CARGAR los plugins que hay en @plugin_names en vez de todos
    
    
    
    ignore = ['.','..','plugin.rb']
    #carpeta=Dir.open("progs/ruby/seqtrimii/plugins")

    plugins_path = File.expand_path(File.join(File.dirname(__FILE__), "../plugins"))
    if !File.exists?(plugins_path)
    	raise "Plugin folder does not exists"
    end
    
    # carpeta=Dir.open(plugins_path)
    entries = Dir.glob(File.join(plugins_path,'*.rb'))
    # carpeta.
    entries.each do |plugin|
      if !ignore.include?(plugin)
          require plugin
      end # end  if
    end # end  each
  end # end  def
  
  
end
