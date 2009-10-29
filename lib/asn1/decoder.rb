# $Id: decoder.rb 94 2006-06-20 15:56:23Z mks $

module ASN1

  class ASN1Decoder

    #
    # Decoder
    #

    DECODE_METHODS = {
      :opBOOLEAN  => :_dec_boolean,
      :opINTEGER  => :_dec_integer,
      :opBITSTR   => :_dec_bitstring,
      :opSTRING   => :_dec_string,
      :opNULL     => :_dec_null,
      :opOBJID    => :_dec_object_id,
      :opREAL     => :_dec_real,
      :opSEQUENCE => :_dec_sequence,
      :opSET      => :_dec_set,
      :opUTIME    => :_dec_time,
      :opGTIME    => :_dec_time,
      :opANY      => nil,
      :opCHOICE   => nil,
      :opROID     => :_dec_object_id,
      :opBCD      => :_dec_bcd,
    }

    JOIN_CONSTRUCTED_STRING = {
      :opBITSTR => proc { |arg| [arg.map {|e| e[0]}.join, arg[-1][1]] },
      :opSTRING => proc { |arg| arg.join },
    }

    class Result
      attr_reader :value

      def initialize(is_loop)
        @is_loop = is_loop
        @value = @is_loop ? [] : {}
      end

      def set(value, varname = nil)
        if @is_loop
          @value.push value
        elsif varname
          @value[varname] = value
        else
          @value = value
        end
      end
    end

    attr_accessor :option

    # option => {
    #   :time     => :unixtime, :withzone or :raw (default :unixtime)
    # }

    def initialize
      @option = {}
    end

    def decode(buf, tree, oidtable = {})
      @oidtable = oidtable
      _setbuf(buf)
      return _decode(tree, 0, buf.size, false)
    end

    private

    def _setbuf(buf)
      @buf = buf
      @indef_cache = {}
    end

    def _decode(ops, pos, endpos, is_loop)
      result = Result.new(is_loop)
      ops.each do |op|
        if op.tag
          # TAGLOOP
          begin
            tag, len, datapos, nextpos = _decode_tl(pos, endpos)
            if tag.nil?
              break if pos == endpos && (is_loop || op.optional)
              raise ASN1Error, 'decode error'
            elsif tag == op.tag
              val = send(DECODE_METHODS[op.type], op, datapos, len)
              result.set(val, op.name)
              pos = nextpos
            elsif tag == constructive_tag(op.tag) && JOIN_CONSTRUCTED_STRING.has_key?(op.type)
              ctrlist = _decode([op], datapos, datapos+len, true)
              val = JOIN_CONSTRUCTED_STRING[op.type].call(ctrlist)
              result.set(val, op.name)
              pos = nextpos
            elsif is_loop || op.optional
              break
            else
              raise ASN1Error, "decode error #{tag.unpack('H*')}<=>#{op.tag.unpack('H*')} #{pos} #{op.type} #{op.name}"
            end
          end while is_loop && pos < endpos
        else
          # tag is nothing, so it must be ANY or CHOICE
          case op.type
          when :opANY
            # ANYLOOP
            begin
              tag, len, datapos, nextpos = _decode_tl(pos, endpos)
              if tag.nil?
                break if pos == endpos && (is_loop || op.optional)
                raise ASN1Error, 'decode error'
              else
                len += datapos - pos
                handler = op.def_by ? @oidtable[result.value[op.def_by]] : nil
                val = handler ? handler.decode(@buf[pos, len]) : @buf[pos, len]
                result.set(val, op.name)
                pos = nextpos
              end
            end while is_loop && pos < endpos
          when :opCHOICE
            # CHOICELOOP
            begin
              tag, len, datapos, nextpos = _decode_tl(pos, endpos)
              if tag.nil?
                break if pos == endpos && (is_loop || op.optional)
                raise ASN1Error, 'decode error'
              else
                found = false
                op.child.each do |cop|
                  if tag == cop.tag
                    val = send(DECODE_METHODS[cop.type], cop, datapos, len)
                    val = { cop.name => val }
                    result.set(val, op.name)
                    pos = nextpos
                    found = true
                    break
                  elsif cop.tag.nil?
                    val = _decode([cop], pos, nextpos, false) rescue next
                    result.set(val, op.name)
                    pos = nextpos
                    found = true
                    break
                  elsif tag == constructive_tag(cop.tag) && JOIN_CONSTRUCTED_STRING.has_key?(cop.type)
                    ctrlist = _decode([cop], datapos, datapos+len, true)
                    val = JOIN_CONSTRUCTED_STRING[op.type].call(ctrlist)
                    val = { cop.name => val }
                    result.set(val, op.name)
                    pos = nextpos
                    found = true
                    break
                  end
                end
                raise ASN1Error, 'decode error' if !found && !op.optional
              end
            end while is_loop && pos < endpos
          else
            raise 'Internal error.'
          end
        end
      end
      return result.value
    end

    def _dec_boolean(op, pos, *)
      return @buf[pos] != 0
    end

    def _dec_integer(op, pos, len)
      n = @buf[pos]
      n -= 0x100 if n >= 0x80
      return @buf[pos+1, len-1].unpack('C*').inject(n) {|a,b| a*256 + b}
    end

    def _dec_bitstring(op, pos, len)
      return [@buf[pos+1, len-1], (len-1)*8 - @buf[pos]]
    end

    def _dec_string(op, pos, len)
      return @buf[pos, len]
    end

    def _dec_null(*)
      return nil
    end

    def _dec_object_id(op, pos, len)
      data = @buf[pos, len].unpack('w*')
      if op.type == :opOBJID && data.size > 1
        data[0, 1] = [data[0] / 40, data[0] % 40]
      end
      return data.join('.')
    end

    def _dec_real(op, pos, len)
      return 0.0 if len.zero?
      first = @buf[pos]
      if first & 0x80 != 0
        explen = first & 0x03
        expstart = pos + 1
        if explen == 3
          expstart += 1
          explen = @buf[pos + 1]
        else
          explen += 1
        end
        exponent = _dec_integer(nil, expstart, explen)

        mantissa = 0.0
        @buf[expstart + explen, len - 1 - explen].reverse.each_byte do |b|
          exponent += 8
          mantissa = (mantissa + b) / 256.0
        end

        mantissa *= 1 << ((first >> 2) & 0x03)
        mantissa = -mantissa if first & 0x40 != 0

        base = [2,8,16][(first >> 4) & 0x03]

        return mantissa * (base ** exponent)
      elsif first & 0x40 != 0
        return  1.0 / 0.0 if first == 0x40  # +Infinity
        return -1.0 / 0.0 if first == 0x41  # -Infinity
      elsif @buf[pos, len] =~ /^.([-+]?)0*(\d+(?:\.\d+(?:[Ee][-+]?\d+)?)?)$/
        return "#{$1}#{$2}".to_f
      end
      raise ASN1Error, 'REAL decode error'
    end

    def _dec_sequence(op, pos, len)
      if op.child
        return _decode(op.child, pos, pos + len, op.loop)
      else
        return @buf[pos, len]
      end
    end

    def _dec_set(op, pos, len)
      ch = op.child
      return _dec_sequence(op, pos, len) if op.loop || !ch

      result = {}
      endpos = pos + len
      done_flags = Array.new(ch.size, false)

      while pos < endpos
        tag, len, datapos, nextpos = _decode_tl(pos, endpos)
        raise ASN1Error, 'decode error' unless tag
        any = nil
        done = false

        ch.each_with_index do |op, idx|
          if op.tag
            if tag == op.tag
              val = send(DECODE_METHODS[op.type], op, datapos, len)
              result[op.name] = val if op.name
              done = idx
              break
            elsif tag == constructive_tag(op.tag) && JOIN_CONSTRUCTED_STRING.has_key?(op.type)
              ctrlist = _decode([op], datapos, datapos+len, true)
              result[op.name] = JOIN_CONSTRUCTED_STRING[op.type].call(ctrlist)
              done = idx
              break
            else
              next
            end
          elsif op.type == :opANY
            any = idx
          elsif op.type == :opCHOICE
            op.child.each do |cop|
              if tag == cop.tag
                val = send(DECODE_METHODS[cop.type], cop, datapos, len)
                if op.name
                  result[op.name] = { cop.name => val }
                else
                  result[cop.name] = val
                end
                done = idx
                break
              elsif tag == constructive_tag(cop.tag) && JOIN_CONSTRUCTED_STRING.has_key?(cop.type)
                ctrlist = _decode([cop], datapos, datapos+len, true)
                val = JOIN_CONSTRUCTED_STRING[cop.type].call(ctrlist)
                if op.name
                  result[op.name] = { cop.name => val }
                else
                  result[cop.name] = val
                end
                done = idx
                break
              end
            end
            break if done
          else
            raise ASN1Error, 'internal error'
          end
        end

        if !done && any
          varname = ch[any].name
          result[varname] = @buf[pos, len + datapos - pos] if varname
          done = any
        end

        raise ASN1Error, 'decode error' if !done || done_flags[done]
        done_flags[done] = true

        pos = nextpos
      end

      raise ASN1Error, 'decode error' unless endpos == pos

      ch.each_index do |idx|
        raise ASN1Error, 'decode error' if !done_flags[idx] && !ch[idx].optional
      end

      return result
    end

    def _dec_time(op, pos, len)
      @option[:time] ||= :unixtime

      return @buf[pos, len] if @option[:time] == :raw

      bits = /^((?:\d\d)?\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)((?:\.\d{1,3})?)(([-+])(\d\d)(\d\d)|Z)/.match(@buf[pos, len]).captures or raise ASN1Error, 'bad time format'
      year, mon, mday, hour, min, sec = bits[0..5].map {|n| n.to_i }
      usec = (bits[6].to_f * 1000000).to_i
      tz, tz_sign, tz_hour, tz_min = bits[7..10]

      if year < 50
        year += 2000
      elsif year < 100
        year += 1900
      end

      time = Time.utc(year, mon, mday, hour, min, sec, usec).to_f
      time = time.to_i if usec == 0
      offset = 0

      if tz != 'Z'
        offset = tz_hour.to_i * 3600 + tz_min.to_i * 60
        offset = -offset if tz_sign == '-'
        time -= offset
      end

      case @option[:time]
      when :withzone
        return [time, offset]
      when :unixtime
        return time
      else
        raise 'Unknown time option'
      end
    end

    def _dec_bcd(op, pos, len)
      return @buf[pos,len].unpack('H*')[0].sub(/[fF]$/, '').to_i
    end

    def _decode_tl(pos, endpos)
      # get tag and length.
      tag = @buf[pos,1]
      pos += 1

      if tag[0] & 0x1f == 0x1f
        begin
          tag << @buf[pos]
          pos += 1
        end until tag[-1] & 0x80 == 0
      end

      len = @buf[pos]
      pos += 1
      indef = false   # indefinite form
      unless len & 0x80 == 0
        if (len &= 0x7F) != 0
          len, pos = @buf[pos,len].unpack('C*').inject {|a,b| a*256 + b}, pos + len
        else
          # get data length of indefinite form
          len = _scan_indef(pos, endpos) or return nil
          indef = true
        end
      end

      nextpos = pos + len
      nextpos += 2 if indef
      return nil if nextpos > endpos

      # return the tag, the length of the data, the position of the data
      # and the position of the next tag
      return [tag, len, pos, nextpos]
    end

    def _scan_indef(pos, endpos)
      # return cached data if already scanned
      return @indef_cache[pos] if @indef_cache.has_key?(pos)

      larr = [pos]
      depth = [0]

      until depth.empty?
        return nil if pos+2 > endpos

        if @buf[pos,2] == "\0\0"
          # cache length data
          idx = depth.shift
          @indef_cache[larr[idx]] = pos - larr[idx]
          pos += 2
          next
        end

        # skip tag
        if @buf[pos] & 0x1f == 0x1f
          pos += 1
          until @buf[pos] & 0x80 == 0
            pos += 1
          end
        end
        pos += 1
        return nil if pos >= endpos

        len = @buf[pos]
        pos += 1

        if len & 0x80 != 0
          if (len &= 0x7F) != 0
            return nil if pos+len > endpos
            pos += len + @buf[pos,len].unpack('C*').inject {|a,b| a*256 + b}
          else
            # reserve another list element
            larr.push pos
            depth.unshift larr.size-1
          end
        else
          pos += len
        end
      end
      return @indef_cache[larr[0]]
    end

    def constructive_tag(tag)
      t = tag.dup
      t[0] |= TAG_CONSTRUCTIVE
      return t
    end

  end # class ASN1Decoder

end # module ASN1
