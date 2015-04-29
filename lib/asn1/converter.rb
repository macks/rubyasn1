module ASN1
  class ASN1Converter

    attr_reader :error, :backtrace

    def initialize(asn1tree)
      @tree = asn1tree
      @oidtable = {}
      @encoder = ASN1Encoder.new
      @decoder = ASN1Decoder.new
      @default_type = asn1tree.keys[0]
    end

    def select(type)
      raise "Unknown type: #{type}" unless @tree.has_key?(type)
      @default_type = type
      self
    end

    def typeinfo(type = @default_type)
      if @tree[type].size == 1
        @tree[type][0]
      else
        @tree[type]
      end
    end

    def register_oid(oid, handler)
      @oidtable[oid] = handler
    end

    def enc_opt
      @encoder.option
    end

    def enc_opt=(opt)
      @encoder.option = opt
    end

    def dec_opt
      @decoder.option
    end

    def dec_opt=(opt)
      @decoder.option = opt
    end

    def encode(pdu, type = nil)
      type ||= @default_type
      raise "Unknown type: #{type}" unless @tree.has_key?(type)
      return @encoder.encode(pdu, @tree[type], @oidtable)
    end

    def decode(buf, type = nil)
      type ||= @default_type
      raise "Unknown type: #{type}" unless @tree.has_key?(type)
      return @decoder.decode(buf, @tree[type], @oidtable)
    end

  end # class ASN1Converter
end