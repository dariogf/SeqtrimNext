

class SequenceGroup
  
  attr_accessor :stats,:output_text,:output_files
  
  
  def initialize(seqs)
    @stats={}
    @seqs=seqs
    @output_text={}
    @output_files={}
    
  end
  
  
  def push(seq)
    @seqs.push seq
  end
  
  def delete(seq)
    @seqs.delete(seq)
  end
  
  def empty?
    return @seqs.empty?
  end
  
  
  def each
      @seqs.each do |seq|
        yield seq
      end
  end
  
  def each_slice(n)
      @seqs.each_slice(n) do |seqs|
        yield seqs
      end
  end
  

  def each_with_index
      @seqs.each_with_index do |seq,i|
        yield seq,i
      end
  end

  
  def reverse_each
      @seqs.reverse_each do |seq|
        yield seq
      end
  end
  
  def add(array)
    @seqs = @seqs + array

    # sort by tuple_id and order in tuple
    @seqs.sort! do |a,b|
      comp = (a.tuple_id <=> b.tuple_id)
      comp.zero? ? (a.order_in_tuple <=> b.order_in_tuple) : comp
    end

    # print
    # @seqs.each do |s|
    #   puts "TID:#{s.tuple_id}, OIT: #{s.order_in_tuple}"
    # end
    
  end
  
  def count
    return @seqs.count
  end
  
  def include?(s)
    return @seqs.include?(s)
  end
  
  def remove_all_seqs
    @seqs=[]
  end
  
  # def job_identifier
  #     return @seqs[0].seq_name
  # end
  
  def inspect
    return "Group with #{@seqs.count} sequences"
  end
  
end