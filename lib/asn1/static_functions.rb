module ASN1

  class ASN1Error < StandardError; end

  def self.encode_tag(tag_class, val)
    case tag_class
    when CLASS_UNIVERSAL, CLASS_APPLICATION, CLASS_CONTEXT, CLASS_PRIVATE
      # do nothing
    else
      raise ASN1Error, sprintf("Bad tag class 0x%x", tag_class)
    end

    if val < 0x1f
      return [tag_class | val].pack('C')
    else
      return [tag_class | 0x1f, val].pack('Cw')
    end
  end

  def self.encode_length(val)
    case
    when val < 0x80
      return val.chr
    when val < 0x100
      return [0x81, val].pack('CC')
    when val < 0x10000
      return [0x82, val].pack('Cn')
    when val < 0x1000000
      return [0x83000000 | val].pack('N')
    when val < 0x100000000
      return [0x84, val].pack('CN')
    else
      raise 'Too large length.'
    end
  end

  def self.decode_tag(buf)
    tag_class = buf[0] & 0xe0
    val = buf[0] & 0x1f

    if val != 0x1f
      return [1, tag_class, val]
    else
      val = 0
      n = 0
      begin
        n += 1
        val = (val << 7) + (buf[n] & 0x7f)
      end until (buf[n] & 0x80) == 0
      return [1 + n, tag_class, val]
    end
  end

  def self.decode_length(buf)
    len = buf[0]
    if len < 0x80
      return [1, len]
    else
      len &= 0x7f
      return nil if len >= buf.size
      return [1, -1] if len == 0
      return [1 + len, buf[1,len].unpack('C*').inject {|a,b| a * 256 + b }]
    end
  end

  def self.parse(asn1desc)
    ASN1::Parser.new.parse(asn1desc)
  end


end # module ASN1
