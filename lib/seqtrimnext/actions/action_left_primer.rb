require "seqtrim_action"


class ActionLeftPrimer < SeqtrimAction

  def initialize(start_pos,end_pos)
    super(start_pos,end_pos)
    @cut =true

  end

  def apply_decoration(char)
    return char.blue.underline
  end


end
