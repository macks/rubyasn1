# $Id: test_04opt.rb 82 2005-12-22 18:13:32Z mks $

$:.unshift './lib'
require 'test/unit'
require 'asn1'

class Asn1Test_Optional < Test::Unit::TestCase

  def test_opt
    assert_not_nil(p = ASN1::Parser.new)

    assert_not_nil(c = p.parse(%q<
      integer INTEGER OPTIONAL,
      str STRING
    >))

    result = [0x4, 0x3, ?a, ?b, ?c].pack('C*')
    val = { :str => 'abc' }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    result = [0x2, 0x1, 0x9, 0x4, 0x3, ?a, ?b, ?c].pack('C*')
    val = { :integer => 9, :str => 'abc' }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    assert_raise(ASN1::ASN1Error) { c.encode( :integer => 9 ) }

    assert_not_nil(c = p.parse(%q<
      SEQUENCE {
        bar [0] SET OF INTEGER OPTIONAL,
        str OCTET STRING
      }
    >))

    result = ['3006040446726564'].pack('H*')
    val = { :str => 'Fred' }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    result = ['3011a009020101020105020103040446726564'].pack('H*')
    val = { :str => 'Fred', :bar => [1,5,3] }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))
  end

end
