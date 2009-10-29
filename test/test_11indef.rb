# $Id: test_11indef.rb 51 2005-12-01 18:37:07Z mks $

$:.unshift './lib'
require 'test/unit'
require 'asn1'

class Asn1Test_IndefiniteLengthEncoding < Test::Unit::TestCase

  def test_indefinite
    assert_not_nil(p = ASN1::Parser.new)
    assert_not_nil(c = p.parse(%<
      GroupOfThis ::= [1] OCTET STRING
      GroupOfThat ::= [2] OCTET STRING
      Item        ::= [3] SEQUENCE {
        aGroup GroupOfThis OPTIONAL,
        bGroup GroupOfThat OPTIONAL
      }
      Items       ::= [4] SEQUENCE OF Item
      List        ::= [5] SEQUENCE { list Items }
    >))

    buf = [
      0xa5, 0x80,
        0xa4, 0x80,
          0xa3, 0x80,
            0x81, 0x03, ?A, ?A, ?A,
          0,0,
          0xa3, 0x80,
            0x82, 0x03, ?B, ?B, ?B,
          0,0,
          0xa3, 0x80,
            0x81, 0x03, ?C, ?C, ?C,
            0x82, 0x03, ?D, ?D, ?D,
          0,0,
        0,0,
      0,0,
    ].pack('C*')
    val = { :list => [
      { :aGroup => 'AAA' },
      { :bGroup => 'BBB' },
      { :aGroup => 'CCC', :bGroup => 'DDD' }
    ]}

    c.select('List')
    assert_equal(val, c.decode(buf))
  end

end
