# $: << '/Users/dariogf/progs/ruby/gems/scbi_plot/lib'

require 'scbi_plot'
# require 'gnu_plot_graph'

class GraphStats

  def initialize(stats,initial_stats=nil)
    #load stats
    init_stats=initial_stats
    
    if init_stats.nil?
      if File.exists?(File.join(OUTPUT_PATH,'initial_stats.json'))
        r=File.read(File.join(OUTPUT_PATH,'initial_stats.json'))
        init_stats= JSON::parse(r)
      else
        init_stats=[]
      end
      
    end
    # puts init_stats.to_json
    #r=File.read(File.join(File.dirname(__FILE__),'stats.json'))
    if !File.exists?('graphs')
      Dir.mkdir('graphs')
    end
    @stats=stats

    @stats.each do |plugin_name,plugin_value|
      # get plugin class
      begin
        plugin_class = Object.const_get(plugin_name)
      rescue Exception => e
        # puts "RESCUE",e.message,e.backtrace
        plugin_class = Plugin
      end
          

      plugin_value.keys.each do |stats_name|
        puts "Plotting #{stats_name} from #{plugin_name}"
        # if graph is not ignored
        if !plugin_class.graph_ignored?(stats_name)

          x=[]
          y=[]

          # get filename
          file_name=File.join('graphs',plugin_class.get_graph_filename(plugin_name,stats_name)+'.png')

          # create new graph object
          plot=ScbiPlot::Histogram.new(file_name,plugin_class.get_graph_title(plugin_name,stats_name))

          plugin_class.auto_setup(plugin_value[stats_name],stats_name,x,y)

          # puts plugin_class.name.to_s
          # plot_setup returns true if it has already handled the setup of the plot, if not, handle here
          if !plugin_class.plot_setup(plugin_value[stats_name],stats_name,x,y,init_stats,plot)
            if !x.empty? && !y.empty? && (x.length==y.length)

              plot.x_label= "Length"
              plot.y_label= "Count"

              plot.add_x(x)
              plot.add_y(y)
              
              plot.do_graph
            end
            
          end

          # if !x.empty? && !y.empty? && (x.length==y.length)
          #   
          # end
        end
      end
    end

  end

end
