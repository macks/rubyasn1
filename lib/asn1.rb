# $Id: asn1.rb 95 2006-06-20 15:57:46Z mks $
# Copyright (C) 2005 MATSUYAMA Kengo <macksx@gmail.com>. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the GNU General Public License version 2, or any later version.

module ASN1

  class ASN1Error < StandardError; end

  # ASN.1 tag values
  TAG_BOOLEAN           = 0x01
  TAG_INTEGER           = 0x02
  TAG_BIT_STRING        = 0x03
  TAG_OCTET_STRING      = 0x04
  TAG_NULL              = 0x05
  TAG_OBJECT_IDENTIFIER = 0x06
  TAG_OBJECT_DESCRIPTOR = 0x07
  TAG_EXTERNAL          = 0x08
  TAG_REAL              = 0x09
  TAG_ENUMERATED        = 0x0a
  TAG_UTF8_STRING       = 0x0c
  TAG_RELATIVE_OID      = 0x0d
  TAG_SEQUENCE          = 0x10
  TAG_SET               = 0x11
  TAG_NUMERIC_STRING    = 0x12
  TAG_PRINTABLE_STRING  = 0x13
  TAG_TELETEX_STRING    = 0x14
  TAG_VIDEOTEX_STRING   = 0x15
  TAG_IA5_STRING        = 0x16
  TAG_UTC_TIME          = 0x17
  TAG_GENERALIZED_TIME  = 0x18
  TAG_GRAPHIC_STRING    = 0x19
  TAG_VISIBLE_STRING    = 0x1a
  TAG_GENERAL_STRING    = 0x1b
  TAG_CHARACTER_STRING  = 0x1c
  TAG_BMP_STRING        = 0x1e

  # ASN.1 tag classes
  CLASS_UNIVERSAL       = 0x00
  CLASS_APPLICATION     = 0x40
  CLASS_CONTEXT         = 0x80
  CLASS_PRIVATE         = 0xc0

  # primitive or constructive
  TAG_PRIMITIVE         = 0x00
  TAG_CONSTRUCTIVE      = 0x20

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


  class ASN1Type

    attr_accessor :name, :tag, :type, :child, :loop, :optional, :def_by

    def initialize(arg = {})
      @name = arg[:name] if arg[:name]
      @tag  = arg[:tag]  if arg[:tag]
      @type = arg[:type] if arg[:type]
      @child = arg[:child] if arg[:child]
      @def_by = arg[:def_by] if arg[:def_by]
      @loop = arg[:loop] || false
      @optional = arg[:optional] || false
    end

    def members
      if @name
        @name
      elsif ! @child.is_a?(Array) || @child.empty?
        nil
      elsif @child.size == 1
        @child[0].members
      else
        @child.map {|c| c.name}
      end
    end

    def tag_explicit!
      new_op = ASN1Type.new(
        :type  => self.type,
        :child => self.child,
        :loop  => self.loop,
        :optional=> false
      )
      self.type  = 'SEQUENCE'
      self.child = [new_op]
      self.loop  = false
      return self
    end

    def tag_constructive!
      if self.tag && self.tag[0] & ASN1::TAG_CONSTRUCTIVE == 0
        self.tag[0] |= ASN1::TAG_CONSTRUCTIVE
      end
    end

  end # class ASN1Type


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

end # module ASN1


require 'asn1/parser'
require 'asn1/encoder'
require 'asn1/decoder'

if $0 == __FILE__
  require 'pp'
  p = ASN1::Parser.new
  if c = p.parse(ARGF.read)
    pp c
  else
    pp p.error, p.backtrace
  end
end
