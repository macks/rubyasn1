# $Id: test_02seq.rb 51 2005-12-01 18:37:07Z mks $

$:.unshift './lib'
require 'test/unit'
require 'asn1'

class Asn1Test_Sequence < Test::Unit::TestCase

  def test_seq
    assert_not_nil(p = ASN1::Parser.new)

    assert_not_nil(c = p.parse(%<
      SEQUENCE {
        integer INTEGER,
        bool BOOLEAN,
        str STRING
      }
    >))
    result = [0x30, 0x10, 0x02, 0x01, 0x01, 0x01, 0x01, 0x00,
              0x04, 0x08, 0x41, 0x20, 0x73, 0x74, 0x72, 0x69,
              0x6E, 0x67].pack('C*')
    assert_equal(result, c.encode( :integer => 1, :bool => false, :str => 'A string' ))
    assert_not_nil(ret = c.decode(result))
    assert_equal(1, ret[:integer])
    assert(!ret[:bool])
    assert_equal('A string', ret[:str])

    assert_not_nil(c = p.parse(%<
      seq SEQUENCE {
        integer INTEGER,
        bool BOOLEAN,
        str STRING
      }
    >))
    assert_equal(result, c.encode( :seq => { :integer => 1, :bool => false, :str => 'A string' } ))
    assert_not_nil(ret = c.decode(result))
    assert_equal(1, ret[:seq][:integer])
    assert(!ret[:seq][:bool])
    assert_equal('A string', ret[:seq][:str])

    assert_not_nil(c = p.parse(%<
      SEQUENCE {
        real  REAL,
        real2 REAL
      }
    >))
    result = ['300b090380fbcc090480fa9c34'].pack('H*')
    val = { :real => 6.375, :real2 => 624.8125 }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))
  end

end
