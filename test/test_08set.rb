# $Id: test_08set.rb 51 2005-12-01 18:37:07Z mks $

$:.unshift './lib'
require 'test/unit'
require 'asn1'

class Asn1Test_Set < Test::Unit::TestCase

  def test_set
    assert_not_nil(p = ASN1::Parser.new)
    assert_not_nil(c = p.parse(%<
      SET {
        integer INTEGER,
        bool BOOLEAN,
        str STRING
      }
    >))

    result = [0x31, 0x10, 0x01, 0x01, 0x00, 0x02, 0x01, 0x09,
              0x04, 0x08, 0x41, 0x20, 0x73, 0x74, 0x72, 0x69,
              0x6E, 0x67].pack('C*')
    val = { :integer => 9, :bool => false, :str => 'A string' }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    assert_not_nil(c = p.parse(%<
      SET {
        bool BOOLEAN,
        str STRING,
        integer INTEGER
      }
    >))
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))
  end

end
