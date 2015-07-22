require "seqtrim_action"

class ActionRightPrimer < SeqtrimAction

  def initialize(start_pos,end_pos)
    super(start_pos,end_pos)
    @cut =true

  end
  #
  # def apply_to(seq)
  #
  #    # seq.seq_fasta = seq.seq_fasta.slice(start_pos,end_pos)
  #    $LOG.debug " Applying #{self.class} . BEGIN: #{@start_pos}   END: #{@end_pos}  "
  #
  # end

  def apply_decoration(char)
    return char.blue.underline

    #  return char.magenta.negative
  end


end
