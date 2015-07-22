########################################################
# Author: Almudena Bocinos Rioboo
#
# Defines the main methods that are necessary to execute PluginFindPolyATs

#
# Inherit: Plugin
########################################################

require "plugin"
require "global_match"

def overlap(polys,mi_start,mi_end)

  # overlap = polys.find{|e| ( mi_start < e['end'])}
  overlap = polys.find{|e| ( overlapX?(mi_start,mi_end, e['begin'],e['end']) )}
  # puts " Overlap #{mi_start} #{mi_end} => #{overlap}"

  return overlap
end

# MAX_RUBBISH = 3
MAX_POLY_T_FROM_LEFT = 4
MIN_TN_COUNT=15
MAX_POLY_A_FROM_RIGHT = 10
MIN_MIDDLE_POLY_A_SIZE = 35
MIN_MIDDLE_POLY_T_SIZE = 35
MAX_DUST_DISTANCE_FROM_POLYT=30

class PluginFindPolyAt < Plugin

  # Uses the param poly_at_length to look for at least that number of contiguous A's
  def find_polys(ta,seq)
    #minn = poly_at_length
    # puts "="*20 + seq.seq_name + "="*20
    
    minn = 4
    m2 = (minn/2)
    m4 = (minn/4)
    r = [-1,0,0]
    re2 = /(([#{ta}]{#{m2},})(.{0,2})([#{ta}]{#{m2},}))/i
    # re2 = /(([#{ta}]{#{m2},})(.{0,3})([#{ta}]{#{m2},}))/i

    # if ta =~/A/
    #   type='ActionPolyA'
    # else
    #   type='ActionPolyT'
    #   poly_base = 'T'
    # end

    matches = re2.global_match(seq.seq_fasta,3)

    # HASH
    polys = []

    # crear una region poly nuevo
    poly = {}
    #i=0

    matches.each do |pattern2|

      #puts pattern2.match[0]
      m_start = pattern2.match.begin(0)+pattern2.offset
      m_end = pattern2.match.end(0)+pattern2.offset-1


      # does one exist in polys with overlap?
      # yes => group it, updated end
      # no => one new

      if (e=overlap(polys,m_start,m_end))
        # puts "OVERLAPS #{e}"
        # found=seq.seq_fasta.slice(e['begin'],m_end-e['begin']+1)
        # if base_percent(poly,ta)>= 60
          e['end'] = m_end
          e['found'] = seq.seq_fasta.slice(e['begin'],e['end']-e['begin']+1)
        # else
        #   puts "Ignored because lowers the base percent of poly"
        # end
        

      else
        poly={}
        poly['begin'] = m_start
        poly['end'] = m_end #  the next pos to pattern's end
        poly['found'] = seq.seq_fasta.slice(poly['begin'],poly['end']-poly['begin']+1)
        polys.push poly
        
        # puts " NEW POLY#{ta}: #{poly}"
        
      end




    end
    
    # polys.each  do |p|
    #   puts "P#{ta}: #{p}, bp: #{base_percent(p['found'],ta)}"
    # end
    
    return polys
    
  end

  
  def find_polyA(seq)
    
    actions=[]
    polys=find_polys('AN',seq)
    poly_base = 'AN'
    type='ActionPolyA'
    
    poly_size=0
    
    # for each poly found cut it, from right to left (reverse order)
    polys.reverse_each do |poly|
      
      poly_size=poly['end'] - poly['begin'] +1
              
      # if polya is near right and is big enought and has a base percent
      
      
      
      # check if poly lenth and percent are above limits
      if (poly['end']>=seq.seq_fasta.length-MAX_POLY_A_FROM_RIGHT) && (poly_size>= @params.get_param('poly_a_length').to_i) && (base_percent(poly,poly_base)>= @params.get_param('poly_a_percent').to_i)

        a = seq.new_action(poly['begin'],poly['end'],type)
        a.right_action=true    #mark as rigth action to get the left insert
        
        actions.push a
        
        add_stats('poly_a_size',poly_size)
        
        # if poly a is not near right but is bigger, then cut
      elsif (poly['end']<<seq.seq_fasta.length-MAX_POLY_A_FROM_RIGHT) && (poly_size>=MIN_MIDDLE_POLY_A_SIZE) && (base_percent(poly,poly_base)>= @params.get_param('poly_a_percent').to_i)
        
        a = seq.new_action(poly['begin'],poly['end'],type)
        a.right_action=true    #mark as rigth action to get the left insert
        
        actions.push a
        
        add_stats('in_middle_poly_a_size',poly_size)
      # else
      #         puts "REJECTED: #{poly}"
        
      end
      if poly['found'].length > @params.get_param('poly_a_length').to_i
        add_stats("poly_#{poly_base}_base_percents","#{poly['found'].length}  #{base_percent(poly,poly_base)}")
      end

    end

    if !actions.empty?
      add_stats('seqs_with_polyA',1)
      seq.add_actions(actions)
      actions=[]
    end

  end

  def find_polyT(seq)
    
    actions=[]
    poly_base = 'TN'
    type='ActionPolyT'
    
    polys=find_polys('TN',seq)
    
    poly_size=0
    check_for_dust=nil
    
    # for each poly found process it

    polys.each do |poly|

      poly_size=poly['end'] - poly['begin'] + 1
      # puts "#{poly}, size: #{poly['found'].length}, bcount:#{base_percent(poly,poly_base)}"
      # check if poly lenth and percent are above limits
      if (poly_size>= @params.get_param('poly_t_length').to_i) && (base_percent(poly,poly_base) >= @params.get_param('poly_t_percent').to_i)

        if (actions.empty?)  # first poly, check if polyT is on the left of sequence

          #if is polyT and is near left, then the sequence is reversed
          if (poly['begin']==0)

            seq.seq_reversed=true
            a = seq.new_action(poly['begin'],poly['end'],type)
            a.left_action=true
            actions.push a
            
            check_for_dust=poly
            
          elsif (poly['begin']<=MAX_POLY_T_FROM_LEFT && base_count(poly,'TN')>=MIN_TN_COUNT)
            
            seq.seq_reversed=true
            a = seq.new_action(poly['begin'],poly['end'],type)
            a.left_action=true
            actions.push a
            
            check_for_dust=poly
          elsif (poly['begin']>MAX_POLY_T_FROM_LEFT && base_count(poly,'TN')>=MIN_MIDDLE_POLY_T_SIZE)
            
            seq.seq_reversed=true
            # seq.seq_rejected=true
            # seq.seq_rejected_by_message='unexpected polyT'
            check_for_dust=poly            
            a = seq.new_action(poly['begin'],poly['end'],'ActionUnexpectedPolyT')
            a.left_action=true
            actions.push a
            add_stats('unexpected_poly_t_count',poly_size)
            
          end

        else # there are multiple polyTs
          
          if (poly['begin']>MAX_POLY_T_FROM_LEFT && base_count(poly,'TN')>=MIN_MIDDLE_POLY_T_SIZE)
            
            seq.seq_reversed=true
            # seq.seq_rejected=true
            # seq.seq_rejected_by_message='unexpected polyT'

            check_for_dust=poly
            
            a = seq.new_action(poly['begin'],poly['end'],'ActionUnexpectedPolyT')
            a.left_action=true
            actions.push a
            add_stats('unexpected_poly_t_count',poly_size)
            
          end
          
        end


          # if (poly['begin']<=MAX_POLY_T_FROM_LEFT*2)
          #   seq.seq_rejected=true
          #   seq.seq_rejected_by_message='polyT found'
          # end

          # @stats[:poly_t_size]={poly_size => 1}
          add_stats('poly_t_size',poly_size)
          


      end

    end

    if !actions.empty?
      add_stats('seqs_with_polyT',1)
      seq.add_actions(actions)
      
      actions=[]
      if check_for_dust && !seq.seq_fasta.nil? && !seq.seq_fasta.empty?
        dust_masker=DustMasker.new()
        dust_poly_size=check_for_dust['end']-check_for_dust['begin']+1
        found_dust = dust_masker.do_dust([">"+seq.seq_name,seq.seq_fasta])
        # puts "Checking for dust: #{seq.seq_fasta}"
        # puts found_dust.to_json
        total_dust=0
        last_dust_start=0
        
        if !found_dust.empty?
          found_dust[0].dust.each do |dust|
            start=dust[0]
            stop=dust[1]
            dust_size=dust[1]-dust[0]+1
            total_dust+=dust_size

            # dust must be big enought and be near the polyt to be a induced one
            if (dust_size)>10 && (start<last_dust_start+MAX_DUST_DISTANCE_FROM_POLYT)
              last_dust_start=stop
              a = seq.new_action(start,stop,'ActionInducedLowComplexity')
              # a.left_action=true
              actions.push a
            elsif dust_size>10
              a = seq.new_action(start,stop,'ActionLowComplexity')
              # a.left_action=true
              actions.push a
            end
          end
        end
        
        
        
        if !actions.empty?
          add_stats('poly_t_dust',dust_poly_size)
          seq.add_actions(actions)
        else
          add_stats('poly_t_no_dust',dust_poly_size)
        end
        
        # reject sequences if total dust is greater than 30
        if total_dust>30
          # if seq.seq_fasta.length<50
            seq.seq_rejected=true
            seq.seq_rejected_by_message='low complexity by polyt'
          # end
          
          add_stats('induced_low_complexity',total_dust)
        end
        
        
      end
    end

  end



  def exec_seq(seq,blast_query)
    $LOG.debug "[#{self.class.to_s}, seq: #{seq.seq_name}]: looking for strings of polyAT's into the sequence with a length indicated by the param <poly_at_length>"

    find_polyT(seq)
    find_polyA(seq)

  end

  ######################################################################
  #---------------------------------------------------------------------


  def base_percent(poly,poly_base)

    # count Ts en poly['found']
    s=poly['found']
    ta_count = s.count(poly_base.downcase+poly_base.upcase)

    res=(ta_count.to_f/s.size.to_f)*100
    
    # puts "poly #{s} base percent #{res}"


    return res
  end

  def base_count(poly,poly_base)

    # count bases en poly['found']
    s=poly['found']
    res = s.count(poly_base.downcase+poly_base.upcase)

    # puts "poly #{s} base count #{res}"

    return res
  end


  ######################################################################
  #---------------------------------------------------------------------

  #Returns an array with the errors due to parameters are missing
  def self.check_params(params)
    errors=[]

    comment='Minimum length of a poly-A'
		default_value = 6
		params.check_param(errors,'poly_a_length','Integer',default_value,comment)

    comment='Minimum percent of As in a sequence segment to be considered a poly-A'
    # default_value = 80
    default_value = 75
		params.check_param(errors,'poly_a_percent','Integer',default_value,comment)


    comment='Minimum length of a poly-T'
		default_value = 15
		params.check_param(errors,'poly_t_length','Integer',default_value,comment)

    comment='Minimum percent of Ts in a sequence segment to be considered a poly-T'
    # default_value = 80
    default_value = 75
		params.check_param(errors,'poly_t_percent','Integer',default_value,comment)

    return errors
  end




  private :overlap

end
