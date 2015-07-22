require 'gnuplot'

class GnuPlotGraph

def initialize(file_name,x,y,title=nil)
    $VERBOSE=true
    Gnuplot.open do |gp|
      # histogram
      Gnuplot::Plot.new( gp ) do |plot|
     
        # plot.space= 5 # it's the free space between the first/last value and the begin/end of axis X
        
       #plot.set("xrange [#{xr_min}: #{xr_max}]") 
				if !title
				 title=file_name
				end
				
        plot.title "#{title}"
        plot.xlabel "length"
        plot.ylabel "Number of sequences"
        plot.set "key off" #leyend
        
        
#        plot.set "style fill   solid 1.00 border -1"
#        #plot.set "style histogram clustered gap 0 title offset character 0, 0, 0"
#        plot.set "style data histograms"
#        plot.set "boxwidth 0.2 absolute"
        
# For this next line, lw is linewidth (2-4)?
#plot [XMIN:XMAX] 'myHistogramData' with boxes lw VALUE

        contains_strings=false

        x.each do |v|
  	 	  	begin
  		 	 	  r=Integer(v)
  	 	  	rescue
  		 	 	  contains_strings=true
  		 	 	  break
  	 	    end
  	 	   end
        
        
        if !contains_strings
            # plot.set "xrange [*:*]"
            # puts "INTEGER GRAPH"
				    plot.style "fill  pattern 22  border -1"
				    plot.set "boxwidth 0.2" # Probably 3-5.
				     
				    plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds| 
				      #ds.with=  " boxes lw 1"
              # ds.using=""
				      				      ds.with=  " imp lw 4"
				    end         
        
        else #graph with strings in X axis
            # puts "STRING GRAPH"        
          plot.xlabel ""
            
          plot.set "style fill solid 1.00 border -1"
          plot.set "style histogram clustered gap 1 title offset character 0, 0, 0"
          plot.set "style data histogram"
          plot.set "boxwidth 0.2 absolute"
          if x.count>4 then
            plot.set "xtics offset 0,graph 0 rotate 90"
          end
          # $VERBOSE=true
          # plot.set "style data linespoints"
          # plot.set "xtics border in scale 1,0.5 nomirror rotate by -45  offset character 0, 0, 0"
          
          # s = []
          # # i=0
          # x.each_with_index do |v,i|
          #   #s.push "\"#{v}\""
          #   s.push "#{v} #{i}"
          #   
          #   # i+=1
          # end
          # 
          # 
          # plot.set "xtics (#{s.join(',')})"
          # puts "XTICKS: (#{s.join(',')})"
          # puts "X:"
          #           puts x.join(';')
          #           puts "Y:"
          #           puts y.join(';')
          
          # if more than 20 strings, then keep greater ones
          
          if x.count>20
            # puts "original X:#{x.count}"
            $VERBOSE=true            
            h = {}
            
            x.each_with_index do |x1,i|
              h[x1]=y[i]
            end
            
            # puts h.to_json
            x=[]
            y=[]
            
            10.times do
              ma=h.max_by{|k,v| v}
              if ma
                puts "MAX:",ma.join(' * '),"of",h.values.sort.join(',')
                x.push ma[0]
                y.push ma[1]
                h.delete(ma[0])
              end
            end
            
            # puts "MAX 20 #{x.length}:#{x.join(';')}"
            
            # set key below
            # plot.set "label 3 below" 
            
          end

		      plot.data << Gnuplot::DataSet.new( [x,y] ) do |ds| 
            ds.using = "2:xticlabels(1)"   #show the graph and use labels at x
            # ds.using="2"
		        #ds.with=  " boxes lw 1"
		        # ds.using = "2 t 'Sequences' " #show the legend in the graph          
		      end
          
	      end
         
        if !file_name.nil?
          plot.terminal "png size 800,600"
          plot.output "#{file_name}"
        end
      end
      
   end

end


end
