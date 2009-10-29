# $Id: test_10choice.rb 51 2005-12-01 18:37:07Z mks $

$:.unshift './lib'
require 'test/unit'
require 'asn1'

class Asn1Test_Choice < Test::Unit::TestCase

  def test_choice
    assert_not_nil(p = ASN1::Parser.new)
    assert_not_nil(c = p.parse(%<
      Natural  ::= CHOICE {
        prime   Prime,
        product Product
      }
      Prime    ::= [1] INTEGER
      Product  ::= CHOICE {
        perfect Perfect,
        plain   Plain
      }
      Perfect  ::= [2] INTEGER
      Plain    ::= [3] INTEGER
      Naturals ::= [4] SEQUENCE OF Natural
      List     ::= [5] SEQUENCE { list Naturals }
    >))

    result = [0xa5, 0x0b,  0xa4, 0x09, 0x81, 0x01, 0x0d,
              0x82, 0x01, 0x1c, 0x83, 0x01, 0x2a].pack('C*')
    c.select('List')
    val = { :list => [
      { :prime => 13 },
      { :product => { :perfect => 28 } },
      { :product => { :plain   => 42 } }
    ] }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    assert_not_nil(c = p.parse(' Foo ::= [1] EXPLICIT CHOICE { a NULL } '))
    c.select('Foo')
    result = [0xA1, 0x02, 0x05, 0x00].pack('C*')
    val = { :a => nil }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))
  end

end
