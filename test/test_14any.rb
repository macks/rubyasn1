# $Id: test_14any.rb 51 2005-12-01 18:37:07Z mks $

$:.unshift './lib'
require 'test/unit'
require 'asn1'

class Asn1Test_Any < Test::Unit::TestCase

  def test_any
    assert_not_nil(asn_str = ASN1::Parser.new.parse(' string STRING '))
    assert_not_nil(asn_seq = ASN1::Parser.new.parse(%<
      SEQUENCE {
        integer INTEGER,
        str STRING
      }
    >))

    assert_not_nil(p = ASN1::Parser.new)
    assert_not_nil(c = p.parse(%<
      type OBJECT IDENTIFIER,
      content ANY DEFINED BY type
    >))
    c.register_oid('1.1.1.1', asn_str)
    c.register_oid('1.1.1.2', asn_seq)

    result = [0x06, 0x03, 0x29, 0x01, 0x01, 0x04, 0x0d, 0x4a, 0x75,
              0x73, 0x74, 0x20, 0x61, 0x20, 0x73, 0x74, 0x72, 0x69,
              0x6e, 0x67].pack('C*')
    val = {
      :type => '1.1.1.1',
      :content => { :string => 'Just a string'}
    }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    result = [0x06, 0x03, 0x29, 0x01, 0x02, 0x30, 0x11, 0x02,
              0x01, 0x01, 0x04, 0x0c, 0x61, 0x6e, 0x64, 0x20,
              0x61, 0x20, 0x73, 0x74, 0x72, 0x69, 0x6e, 0x67].pack('C*')
    val = {
      :type => '1.1.1.2',
      :content => { :integer => 1, :str => 'and a string' }
    }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))
  end

end
