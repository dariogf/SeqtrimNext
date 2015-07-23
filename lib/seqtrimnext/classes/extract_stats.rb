######################################
# Author:: Almudena Bocinos Rioboo
# Extract stats like mean of sequence's length
######################################

# $: << '/Users/dariogf/progs/ruby/gems/scbi_plot/lib'
# $: << '/Users/dariogf/progs/ruby/gems/scbi_math/lib'

require 'scbi_plot'
require "scbi_math"

class ExtractStats

  def initialize(sequence_readers,params)

    @sequence_lengths = []         #array of sequences lengths
    @length_frequency = []      #number of sequences of each size (frequency)
    @keys={}  #found keys
    @params = params
    @use_qual=sequence_readers.first.with_qual?
    # @params.get_param('use_qual')

    @totalnt=0
    @qv=[]


    @sequence_lengths_stats, @length_frequency_stats, @quality_stats = extract_stats_from_sequences(sequence_readers)


    set_params_and_results

    plot_lengths

    plot_qualities if @use_qual

    print_global_stats

  end

  def extract_stats_from_sequences(sequence_readers)
    sequence_readers.each do |sequence_reader|


      sequence_reader.each do |name_seq,fasta_seq,qual|
        l = fasta_seq.length

        @totalnt+=l

        #save all lengths
        @sequence_lengths.push l

        # add key value
        add_key(fasta_seq[0..3].upcase)

        # add fasta length
        @length_frequency[fasta_seq.length] = (@length_frequency[fasta_seq.length] || 1 ) + 1

        #extract qv values
        extract_qv_from_sequence(qual) if @use_qual

        # print some progress info
        if (sequence_reader.num_seqs % 10000==0)
          puts "Calculating stats: #{sequence_reader.num_seqs}"
        end

      end
    end

    length_stats = ScbiNArray.to_na(@sequence_lengths)
    length_frequency_stats = ScbiNArray.to_na(@length_frequency.map{|e| e || 0})
    quality_stats = ScbiNArray.to_na(@qv) if @use_qual

    return [length_stats, length_frequency_stats, quality_stats]
  end

  def plot_lengths

    ## PLOT RESULTS
    if !File.exists?('graphs')
      Dir.mkdir('graphs')
    end


    x = []
    y = []

    x =(0..@length_frequency.length-1).collect.to_a
    y = @length_frequency.map{|e| e || 0}

    file_name = 'graphs/size_stats.png'

    p=ScbiPlot::Lines.new(file_name,'Stats of sequence sizes')
    p.x_label= "Sequence length"
    p.y_label= "Number of sequences"

    p.add_x(x)

    p.add_series('sizes', y,'impulses',2)

    p.add_vertical_line('Mode',@length_frequency_stats.fat_mode[0])

    p.add_vertical_line('L',@params.get_param('min_sequence_size_raw').to_i)
    p.add_vertical_line('H',@params.get_param('max_sequence_size_raw').to_i)

    p.do_graph


  end

  def plot_qualities

    if !File.exists?('graphs')
      Dir.mkdir('graphs')
    end
    minimum_qual_value = @params.get_param('min_quality').to_i

    # get qualities values
    x=[]
    y=[]
    min=[]
    max=[]
    qual_limit=[]

    @qv.each_with_index do |e,i|
      x << i
      y << (e[:tot]/e[:nseq])
      min << (e[:min])
      max << (e[:max])
      qual_limit << minimum_qual_value
        # puts "#{i}: #{e[:tot]/e[:nseq]}"
      end

    # make plot of qualities

    file_name='graphs/qualities.png'

  	 p=ScbiPlot::Lines.new(file_name,'Stats of sequence qualities')
     p.x_label= "Nucleotide position"
     p.y_label= "Quality value"

      p.add_x(x)

      p.add_series('mean', y)
      p.add_series('min', min)
      p.add_series('max', max)
      p.add_series('qual limit',qual_limit)


      p.do_graph
  end
  
   
   def add_qv(q,i)
     if !@qv[i]
       @qv[i]={:max => 0, :min => 1000000, :nseq => 0, :tot => 0}
     end
     
     # set max
     @qv[i][:tot]+=q
     @qv[i][:nseq]+=1
     @qv[i][:min]=[@qv[i][:min],q].min
     @qv[i][:max]=[@qv[i][:max],q].max
     
   end
   
   def extract_qv_from_sequence(qual)
     qual.each_with_index do |q,i|
       add_qv(q,i)
     end
   end

  def add_key(key)
    if @keys[key].nil?
	    @keys[key]=1
    else
	    @keys[key]+=1
    end
  end

  def get_max_key
    return @keys.keys.sort{|e1,e2| @keys[e1]<=>@keys[e2]}.last
  end
    
  def set_params_and_results

    if @sequence_lengths.empty? 
      puts "No sequences has been sucessfully readed " 
      return
    end
    
    
    # set limiting parameters
    
    @params.set_param('sequencing_key',get_max_key)
    @params.set_param('all_found_keys',@keys.to_json)

    # sequence min size, is taken directly from params file
    # max sequence limit is calculated here 
    if (@sequence_lengths_stats.variance_coefficient<=10) or (@params.get_param('accept_very_long_sequences').to_s=='true')

      # high size limit is calculated with stats
      @params.set_param('max_sequence_size_raw',(@sequence_lengths_stats.max+10).to_i)

    else # > 10 %

      # high size limit is calculated with stats
      @params.set_param('max_sequence_size_raw',(@sequence_lengths_stats.mean+2*@sequence_lengths_stats.stddev).to_i)
    end


  end

def print_global_stats

if !@sequence_lengths_stats.nil?
initial_stats={}
initial_stats[:sequence_count] = @sequence_lengths_stats.size
initial_stats[:smallest_sequence_size] = @sequence_lengths_stats.min
initial_stats[:biggest_sequence_size] = @sequence_lengths_stats.max

initial_stats[:min_sequence_size_raw]=@params.get_param('min_sequence_size_raw')
initial_stats[:max_sequence_size_raw]=@params.get_param('max_sequence_size_raw')
initial_stats[:coefficient_of_variance]=@sequence_lengths_stats.variance_coefficient
initial_stats[:nucleotide_count]=@totalnt
initial_stats[:mode_of_sizes]=@length_frequency_stats.fat_mode[0]
initial_stats[:mean_of_sequence_sizes]=@sequence_lengths_stats.mean

initial_stats[:qv]=@qv
initial_stats[:used_key]=get_max_key
initial_stats[:all_keys]=@keys

File.open(File.join(OUTPUT_PATH,'initial_stats.json'),'w') do |f|
  f.puts JSON.pretty_generate(initial_stats)
end

puts "_"*10+ " STATISTICS "+"_"*10
puts "Total sequence count: #{@sequence_lengths_stats.size}"

puts "Smallest sequence: #{initial_stats[:smallest_sequence_size]} nt"
puts "Biggest sequence : #{initial_stats[:biggest_sequence_size]} nt"
puts "Mean of sequence sizes : #{initial_stats[:mean_of_sequence_sizes]} nt"
puts "Mode of sequence sizes : #{initial_stats[:mode_of_sizes]} nt"

puts "Low size limit : #{initial_stats[:min_sequence_size_raw]} nt"
puts "High size limit : #{initial_stats[:max_sequence_size_raw]} nt"

puts "Coefficient of variation: #{initial_stats[:coefficient_of_variance]} %"
puts "Total nucleotide count: #{initial_stats[:nucleotide_count]} nt"

puts "_"*30


end

end


end
