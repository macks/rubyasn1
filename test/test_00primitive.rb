# $Id: test_00primitive.rb 50 2005-12-01 18:04:51Z mks $

$:.unshift './lib'
require 'test/unit'
require 'asn1'

class Asn1Test_Primivite < Test::Unit::TestCase

  def test_primitive
    assert_equal("\x81",         ASN1.encode_tag(ASN1::CLASS_CONTEXT, 1))
    assert_equal("\x1f\x20",     ASN1.encode_tag(ASN1::CLASS_UNIVERSAL, 32))
    assert_equal("\x5f\x82\x01", ASN1.encode_tag(ASN1::CLASS_APPLICATION, 257))

    assert_equal([1, ASN1::CLASS_CONTEXT, 1],       ASN1.decode_tag("\x81"))
    assert_equal([2, ASN1::CLASS_UNIVERSAL, 32],    ASN1.decode_tag("\x1f\x20"))
    assert_equal([3, ASN1::CLASS_APPLICATION, 257], ASN1.decode_tag("\x5f\x82\x01"))

    assert_equal([45].pack('C*'),             ASN1.encode_length(45))
    assert_equal([0x81,0x8b].pack("C*"),      ASN1.encode_length(139))
    assert_equal([0x82,0x12,0x34].pack("C*"), ASN1.encode_length(0x1234))

    assert_equal([1, 45],     ASN1.decode_length(ASN1.encode_length(45)))
    assert_equal([2, 139],    ASN1.decode_length(ASN1.encode_length(139)))
    assert_equal([3, 0x1234], ASN1.decode_length(ASN1.encode_length(0x1234)))

    assert_not_nil(p = ASN1::Parser.new)

    ##
    ## NULL
    ##

    result = [0x05,0x00].pack('C*')
    assert_not_nil(c = p.parse(' null NULL '))
    assert_equal(result, c.encode( :null => nil ))
    assert_not_nil(ret = c.decode(result))
    assert(ret.has_key?(:null))

    ##
    ## BOOLEAN
    ##

    [nil, false, '', 0, -99].each do |val|
      result = [0x01, 0x01, val ? 0xFF : 0].pack('C*')
      assert_not_nil(c = p.parse(' bool BOOLEAN '))
      assert_equal(result, c.encode( :bool => val ))
      assert_not_nil(ret = c.decode(result))
      assert_equal(!!val, !!ret[:bool])
    end

    ##
    ## INTEGER
    ##

    assert_not_nil(c = p.parse(' integer INTEGER '))
    {
      [0x02, 0x02, 0x00, 0x80].pack('C*')       => 128,
      [0x02, 0x01, 0x80].pack('C*')             => -128,
      [0x02, 0x02, 0xff, 0x01].pack('C*')       => -255,
      [0x02, 0x01, 0x00].pack('C*')             => 0,
      [0x02, 0x03, 0x66, 0x77, 0x99].pack('C*') => 0x667799,
      [0x02, 0x02, 0xFE, 0x37].pack('C*')       => -457,
      [0x02, 0x04, 0x40, 0x00, 0x00, 0x00].pack('C*') => 2**30,
      [0x02, 0x04, 0xC0, 0x00, 0x00, 0x00].pack('C*') => -2**30,
    }.each do |result, val|
      assert_equal(result, c.encode( :integer => val ))
      assert_not_nil(ret = c.decode(result))
      assert_equal(val, ret[:integer])
    end

    assert_not_nil(c = p.parse(' test ::= INTEGER '))
    result = [0x02, 0x01, 0x09].pack('C*')
    assert_equal(result, c.select('test').encode(9))
    assert_not_nil(ret = c.select('test').decode(result))
    assert_equal(9, ret)

    ##
    ## STRING
    ##

    assert_not_nil(t = c = p.parse(' str STRING '))
    {
      [0x04, 0x00].pack('C*')               => '',
      [0x04, 0x08, 'A string'].pack('CCa*') => 'A string',
    }.each do |result, val|
      assert_equal(result, c.encode( :str => val ))
      assert_not_nil(ret = c.decode(result))
      assert_equal(val, ret[:str])
    end

    ##
    ## OBJECT_ID
    ##

    assert_not_nil(c = p.parse(' oid OBJECT IDENTIFIER '))
    {
      [0x06, 0x04, 0x2A, 0x03, 0x04, 0x05].pack('C*') => "1.2.3.4.5",
      [0x06, 0x03, 0x55, 0x83, 0x49].pack('C*')       => "2.5.457",
      [0x06, 0x07, 0x00, 0x11, 0x86, 0x05, 0x01, 0x01, 0x01].pack('C*') => "0.0.17.773.1.1.1",
    }.each do |result, val|
      assert_equal(result, c.encode( :oid => val ))
      assert_not_nil(ret = c.decode(result))
      assert_equal(val, ret[:oid])
    end

    ##
    ## ENUM
    ##

    assert_not_nil(c = p.parse(' enum ENUMERATED '))
    {
      [0x0A, 0x01, 0x00].pack('C*')             => 0,
      [0x0A, 0x01, 0x9D].pack('C*')             => -99,
      [0x0A, 0x03, 0x64, 0x4D, 0x90].pack('C*') => 6573456,
    }.each do |result, val|
      assert_equal(result, c.encode( :enum => val ))
      assert_not_nil(ret = c.decode(result))
      assert_equal(val, ret[:enum])
    end

    ##
    ## BIT STRING
    ##

    assert_not_nil(c = p.parse(' bit BIT STRING '))
    {
      [0x03, 0x02, 0x07, 0x00].pack('C*') =>
        [['0'].pack('B*'), 1, ['0'].pack('B*')],
      [0x03, 0x02, 0x00, 0x33].pack('C*') =>
        ['00110011'].pack('B*'),
      [0x03, 0x04, 0x03, 0x6E, 0x5D, 0xC0].pack('C*') =>
        [['011011100101110111'].pack('B*'), 21, ['011011100101110111'].pack('B*')],
      [0x03, 0x02, 0x01, 0x6E].pack('C*') =>
        [['011011111101110111'].pack('B*'),  7, ['01101110'].pack('B*')],
    }.each do |result, val|
      assert_equal(result, c.encode( :bit => val ))
      assert_not_nil(ret = c.decode(result))
      if val.is_a?(Array)
        assert_equal([val[2], val[1]], ret[:bit])
      else
        assert_equal([val, 8 * val.size], ret[:bit])
      end
    end

    ##
    ## REAL
    ##

    assert_not_nil(c = p.parse(' real REAL '))
    {
      [0x09, 0x00].pack('C*')                   => 0,
      [0x09, 0x03, 0x80, 0xF9, 0xC0].pack('C*') => 1.5,
      [0x09, 0x03, 0xC0, 0xFB, 0xB0].pack('C*') => -5.5,
      [0x09, 0x01, 0x40].pack('C*')             =>  1.0 / 0.0,  # +Infinity
      [0x09, 0x01, 0x41].pack('C*')             => -1.0 / 0.0,  # -Infinity
    }.each do |result, val|
      assert_equal(result, c.encode( :real => val ))
      assert_not_nil(ret = c.decode(result))
      assert_equal(val, ret[:real])
    end

    ##
    ## RELATIVE-OID
    ##

    assert_not_nil(c = p.parse(' roid RELATIVE-OID '))
    {
      [0x0D, 0x05, 0x01, 0x02, 0x03, 0x04, 0x05].pack('C*') => '1.2.3.4.5',
      [0x0D, 0x04, 0x02, 0x05, 0x83, 0x49].pack('C*')       => '2.5.457',
      [0x0D, 0x08, 0x00,  0x00, 0x11, 0x86, 0x05, 0x01, 0x01, 0x01].pack('C*') => '0.0.17.773.1.1.1',
    }.each do |result, val|
      assert_equal(result, c.encode( :roid => val ))
      assert_not_nil(ret = c.decode(result))
      assert_equal(val, ret[:roid])
    end

    ##
    ## BCDString
    ##

    assert_not_nil(c = p.parse(' bcd BCDString '))
    {
      [0x04, 0x04, 0x12, 0x34, 0x56, 0x78].pack('C*') => 12345678,
      [0x04, 0x02, 0x56, 0x4f].pack('C*')             => 564,
    }.each do |result, val|
      assert_equal(result, c.encode( :bcd => val ))
      assert_not_nil(ret = c.decode(result))
      assert_equal(val, ret[:bcd])
    end
  end

end
