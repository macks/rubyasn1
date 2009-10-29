# $Id: encoder.rb 94 2006-06-20 15:56:23Z mks $

module ASN1

  class ASN1Encoder

    #
    # Encoder
    #

    ENCODE_METHODS = {
      :opBOOLEAN  => :_enc_boolean,
      :opINTEGER  => :_enc_integer,
      :opBITSTR   => :_enc_bitstring,
      :opSTRING   => :_enc_string,
      :opNULL     => :_enc_null,
      :opOBJID    => :_enc_object_id,
      :opREAL     => :_enc_real,
      :opSEQUENCE => :_enc_sequence,
      :opSET      => :_enc_sequence,  # SET is the same encoding as sequence
      :opUTIME    => :_enc_time,
      :opGTIME    => :_enc_time,
      :opANY      => :_enc_any,
      :opCHOICE   => :_enc_choice,
      :opROID     => :_enc_object_id,
      :opBCD      => :_enc_bcd,
    }

    attr_accessor :option

    # option => {
    #   :real     => :binary or :text             (default :binary) - not implemented
    #   :time     => :utctime, :withzone or :raw  (default :withzone)
    #   :timezone => seconds                      (default is local timezone)
    # }

    def initialize
      @option = {}
    end

    def encode(hash, tree, oidtable = {})
      @oidtable = oidtable
      @buf = []
      @path = []
      return _encode(tree, hash)
    end

    private

    def _encode(ops, stash)
      ops.each do |op|
        next if op.optional && ! has_key?(stash, op.name)
        if op.name
          @path.push op.name
          raise ASN1Error, "#{@path.join('.')}: Not found." unless has_key?(stash, op.name)
        end
        @buf << op.tag if op.tag

        if stash.is_a?(Hash) || stash.is_a?(Struct)
          send(ENCODE_METHODS[op.type], op, stash, op.name ? stash[op.name] : nil)
        else
          send(ENCODE_METHODS[op.type], op, {}, stash)
        end
        @path.pop if op.name
      end
      return @buf.join
    end

    def _enc_boolean(op, stash, var)
      @buf << [1, var ? 0xFF : 0].pack('CC')
    end

    def _enc_integer(op, stash, var)
      @buf << __enc_integer(var)
    end

    def __enc_integer(var)
      fullbits = var < 0 ? -1 : 0
      bytes = []
      begin
        bytes.unshift(var & 0xff)
        var >>= 8
      end until var == fullbits
      bytes.unshift(fullbits & 0xff) unless (fullbits & 0x80 == bytes[0] & 0x80)
      buf = ASN1.encode_length(bytes.size)
      buf << bytes.pack('C*')
      return buf
    end

    def _enc_bitstring(op, stash, var)
      if var.is_a? Array
        less = (8 - (var[1] & 7)) & 7
        len = (var[1] + 7) / 8
        @buf << ASN1.encode_length(1 + len)
        @buf << less.chr
        @buf << var[0][0,len]
        @buf[-1][-1] &= (0xff << less) if (less.nonzero? && len.nonzero?)
      else
        @buf << ASN1.encode_length(1 + var.size)
        @buf << "\0"
        @buf << var
      end
    end

    def _enc_string(op, stash, var)
      @buf << ASN1.encode_length(var.size)
      @buf << var
    end

    def _enc_null(*)
      @buf << "\0"
    end

    def _enc_object_id(op, stash, var)
      data = var.scan(/\d+/).map {|d| d.to_i }

      if op.type == :opOBJID
        if data.size < 2
          data = [0]
        else
          data[0,2] = data[0] * 40 + data[1]
        end
      end

      s = data.pack('w*')
      @buf << ASN1.encode_length(s.size)
      @buf << s
    end

    def _enc_real(op, stash, var)
      # ISO 6093 NR3 mode only.
      var = var.prec_f
      if var.zero?
        @buf << "\0"
        return
      elsif var.infinite? == 1
        @buf << [0x01, 0x40].pack('C*')
        return
      elsif var.infinite? == -1
        @buf << [0x01, 0x41].pack('C*')
        return
      end

      first = 0x80
      mantissa, exponent = Math.frexp(var)
      if mantissa < 0.0
        mantissa = -mantissa
        first |= 0x40
      end

      m_buf = ''
      e_buf = nil
      while mantissa > 0.0
        n, mantissa = (mantissa * 256.0).divmod(1.0)
        m_buf << n.to_i
      end
      exponent -= 8 * m_buf.size
      e_buf = __enc_integer(exponent)

      # e_buf will be prefixed by a length byte
      if e_buf.size < 5
        e_buf[0] = ''
        first |= e_buf.size - 1
      else
        first |= 0x03
      end

      @buf << ASN1.encode_length(1 + m_buf.size + e_buf.size)
      @buf << first.chr
      @buf << e_buf
      @buf << m_buf
    end

    def _enc_sequence(op, stash, var)
      if op.child
        pos = @buf.size
        if op.loop
          cop = op.child[0]     # there should only be one
          @path.push nil
          var.each_index do |i|
            @path[-1] = i
            @buf << cop.tag if cop.tag
            send(ENCODE_METHODS[cop.type], cop, stash, var[i])
          end
          @path.pop
        else
          _encode(op.child, var || stash)
        end
        length = @buf[pos..-1].inject(0) {|a,b| a += b.size}
        @buf[pos,0] = ASN1.encode_length(length)
      else
        @buf << ASN1.encode_length(var.size)
        @buf << var
      end
    end

    def _enc_any(op, stash, var)
      handler = nil
      if op.def_by && stash[op.def_by]
        if handler = @oidtable[stash[op.def_by]]
          @buf << handler.encode(var)
          return
        end
      end
      @buf << var
    end

    def _enc_choice(op, stash, var)
      nstash = var || stash
      op.child.each do |cop|
        if has_key?(nstash, cop.name)
          @path.push cop.name
          _encode([cop], nstash)
          @path.pop
          return
        end
      end
      raise ASN1Error, "#{@path.join('.')}: No value found for CHOICE"
    end

    def _enc_time(op, stash, var)
      @option[:time] ||= :withzone

      if @option[:time] == :raw
        @buf << ASN1.encode_length(var.size)
        @buf << var
        return
      end

      is_gtime = op.type == :opGTIME

      if var.is_a? Array
        offset = var[1] / 60
        time = var[0] + var[1]
      else
        case @option[:time]
        when :withzone
          if @option[:timezone]
            offset = @option[:timezone] / 60
            time = var + @option[:timezone]
          else
            offset = Time.now.gmt_offset
            time = var + offset
            offset /= 60
          end
        when :utctime
          offset = nil
          time = var
        else
          raise 'Unknown time option.'
        end
      end

      gmtime = Time.at(time).gmtime
      tmp = sprintf('%02d%02d%02d%02d%02d%02d',
        is_gtime ? gmtime.year : gmtime.year % 100,
        gmtime.month, gmtime.mday, gmtime.hour, gmtime.min, gmtime.sec)

      if is_gtime
        sp = sprintf('%.03f', time)
        tmp << sp[-4,4] unless sp =~ /\.000$/
      end

      tmp << (offset ? sprintf('%+03d%02d', offset / 60, offset % 60) : 'Z')
      @buf << ASN1.encode_length(tmp.size)
      @buf << tmp
    end

    def _enc_bcd(op, stash, var)
      str = var.to_s
      str << 'F' if str.size & 1 != 0
      @buf << ASN1.encode_length(str.size / 2)
      @buf << [str].pack('H*')
    end

    def has_key?(var, key)
      if var.is_a?(Hash)
        var.has_key?(key)
      else
        not var[key].nil?
      end
    rescue TypeError, NameError
      nil
    end

  end # class ASN1Encoder

end # module ASN1
