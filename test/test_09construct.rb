# $Id: test_09construct.rb 66 2005-12-19 06:20:23Z mks $

$:.unshift './lib'
require 'test/unit'
require 'asn1'

class Asn1Test_Construct < Test::Unit::TestCase

  def test_contr
    # decode on constructed values.
    assert_not_nil(p = ASN1::Parser.new)
    assert_not_nil(c = p.parse(' str STRING '))
    result = [0x24, 0x80, 0x04, 0x03, 0x61, 0x62, 0x63, 0x04, 0x03, 0x44, 0x45, 0x46, 0x00, 0x00].pack('C*')
    assert_equal({:str => 'abcDEF'}, c.decode(result))

    assert_not_nil(c = p.parse(%<
      SET {
        int INTEGER,
        str STRING
      }
    >))
    result = [0x31, 0x11, 0x24, 0x80, 0x04, 0x03, 0x61, 0x62, 0x63, 0x04, 0x03, 0x44, 0x45, 0x46, 0x00, 0x00, 0x02, 0x01, 0x10].pack('C*')
    assert_equal({:int => 16, :str => 'abcDEF'}, c.decode(result))

    assert_not_nil(c = p.parse(%<
      SET {
        int INTEGER,
        CHOICE {
          str STRING,
          num INTEGER
        }
      }
    >))
    result = [0x31, 0x11, 0x24, 0x80, 0x04, 0x03, 0x61, 0x62, 0x63, 0x04, 0x03, 0x44, 0x45, 0x46, 0x00, 0x00, 0x02, 0x01, 0x10].pack('C*')
    assert_equal({:int => 16, :str => 'abcDEF'}, c.decode(result))
  end

end
