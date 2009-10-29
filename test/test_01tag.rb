# $Id: test_01tag.rb 51 2005-12-01 18:37:07Z mks $

$:.unshift './lib'
require 'test/unit'
require 'asn1'

class Asn1Test_Tag < Test::Unit::TestCase

  def test_tag
    assert_not_nil(p = ASN1::Parser.new)

    assert_not_nil(c = p.parse(' integer [0] INTEGER '))
    result = [0x80, 0x01, 0x08].pack('C*')
    val = { :integer => 8 }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    assert_not_nil(c = p.parse(' integer [APPLICATION 1] INTEGER '))
    result = [0x41, 0x01, 0x08].pack('C*')
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    assert_not_nil(c = p.parse(' integer [CONTEXT 2] INTEGER '))
    result = [0x82, 0x01, 0x08].pack('C*')
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    assert_not_nil(c = p.parse(' integer [UNIVERSAL 3] INTEGER '))
    result = [0x03, 0x01, 0x08].pack('C*')
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    assert_not_nil(c = p.parse(' integer [PRIVATE 4] INTEGER '))
    result = [0xC4, 0x01, 0x08].pack('C*')
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))
  end

end
