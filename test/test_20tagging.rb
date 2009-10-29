# $Id: test_20tagging.rb 65 2005-12-08 05:20:34Z mks $

$:.unshift './lib'
require 'test/unit'
require 'asn1'

class Asn1Test_Tagging < Test::Unit::TestCase

  def test_tagging
    assert_not_nil(p = ASN1::Parser.new)

    assert_not_nil(c = p.parse(%<
      implicit-seq ::= [APPLICATION 5] SEQUENCE {
        m1 [0] INTEGER,
        m2 [1] INTEGER
      }

      explicit-seq ::= [APPLICATION 5] EXPLICIT SEQUENCE {
        m1 [0] EXPLICIT INTEGER,
        m2 [1] EXPLICIT INTEGER
      }
    >))

    bin = %w[65 06 80 01 0a 81 01 14].map {|x| x.hex}.pack('C*')
    pdu = { :m1 => 10, :m2 => 20 }
    c.select('implicit-seq')
    assert_equal(bin, c.encode(pdu))
    assert_equal(pdu, c.decode(bin))

    bin = %w[65 0c 30 0a a0 03 02 01  0a a1 03 02 01 14].map {|x| x.hex}.pack('C*')
    c.select('explicit-seq')
    assert_equal(bin, c.encode(pdu))
    assert_equal(pdu, c.decode(bin))


    assert_not_nil(c = p.parse(%<
      SeqType ::= SEQUENCE {
        type  [0] INTEGER,
        value [1] ChoiceType
      }

      ChoiceType ::= CHOICE {
        int INTEGER,
        str PrintableString
      }
    >))
    bin = %w[30 0b 80 01 0a a1 06 13  04 74 65 73 74].map {|x| x.hex}.pack('C*')
    pdu = { :type => 10, :value => { :str => 'test' } }
    c.select('SeqType')
    assert_equal(bin, c.encode(pdu))
    assert_equal(pdu, c.decode(bin))


    # from ISO/IEC 8825-1 X.690 Sec.8.14 pp.11
    assert_not_nil(c = p.parse(%<
      Type1 ::= VisibleString
      Type2 ::= [APPLICATION 3] IMPLICIT Type1
      Type3 ::= [2] EXPLICIT Type2
      Type4 ::= [APPLICATION 7] IMPLICIT Type3
      Type5 ::= [2] IMPLICIT Type2
    >))
    str = 'Jones'
    {
      'Type1' => %w[1a 05 4a 6f 6e 65 73],
      'Type2' => %w[43 05 4a 6f 6e 65 73],
      'Type3' => %w[a2 07 43 05 4a 6f 6e 65 73],
      'Type4' => %w[67 07 43 05 4a 6f 6e 65 73],
      'Type5' => %w[82 05 4a 6f 6e 65 73],
    }.each do |type, bin|
      bin = bin.map {|x| x.hex}.pack('C*')
      c.select(type)
      assert_equal(bin, c.encode(str))
      assert_equal(str, c.decode(bin))
    end
  end

end
