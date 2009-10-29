# $Id: test_03seqof.rb 51 2005-12-01 18:37:07Z mks $

$:.unshift './lib'
require 'test/unit'
require 'asn1'

class Asn1Test_SequenceOf < Test::Unit::TestCase

  def test_seqof
    assert_not_nil(p = ASN1::Parser.new)

    assert_not_nil(c = p.parse(' ints SEQUENCE OF INTEGER '))
    result = [0x30, 0x0C, 0x02, 0x01, 0x09, 0x02, 0x01, 0x05,
              0x02, 0x01, 0x03, 0x02, 0x01, 0x01].pack('C*')
    val = { :ints => [9,5,3,1] }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    result = [
      0x30, 0x25,
        0x30, 0x11,
          0x04, 0x04, ?f, ?r, ?e, ?d,
          0x30, 0x09,
            0x04, 0x01, ?a,
            0x04, 0x01, ?b,
            0x04, 0x01, ?c,
        0x30, 0x10,
          0x04, 0x03, ?j, ?o, ?e,
          0x30, 0x09,
            0x04, 0x01, ?q,
            0x04, 0x01, ?w,
            0x04, 0x01, ?e,
    ].pack('C*')

    assert_not_nil(c = p.parse(' seq SEQUENCE OF SEQUENCE { str STRING, val SEQUENCE OF STRING } '))
    val = { :seq => [
      { :str => 'fred', :val => %w(a b c) },
      { :str => 'joe',  :val => %w(q w e) },
    ] }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    assert_not_nil(c = p.parse(%q<
      AttributeTypeAndValue ::= SEQUENCE {
        type    STRING,
        value   STRING }

      RelativeDistinguishedName ::= SET OF AttributeTypeAndValue

      RDNSequence ::= SEQUENCE OF RelativeDistinguishedName

      Name ::= CHOICE { -- only one possibility for now --
        rdnSequence  RDNSequence }

      Issuer ::= SEQUENCE { issuer Name }
    >))
    c.select('Issuer')

    result = [
      0x30, 0x26, 0x30, 0x24, 0x31, 0x10, 0x30, 0x06,
      0x04, 0x01, 0x31, 0x04, 0x01, 0x61, 0x30, 0x06,
      0x04, 0x01, 0x32, 0x04, 0x01, 0x62, 0x31, 0x10,
      0x30, 0x06, 0x04, 0x01, 0x33, 0x04, 0x01, 0x63,
      0x30, 0x06, 0x04, 0x01, 0x34, 0x04, 0x01, 0x64].pack('C*')
    val = {
      :issuer => {
        :rdnSequence => [
          [{ :type => '1', :value => 'a' }, { :type => '2', :value => 'b' }],
          [{ :type => '3', :value => 'c' }, { :type => '4', :value => 'd' }],
        ]
      }
    }
    assert_equal(result, c.encode(val))
    assert_equal(val, c.decode(result))

    assert_not_nil(c = p.parse('test ::= SEQUENCE OF INTEGER '))
    result = [0x30, 0x0C, 0x02, 0x01, 0x09, 0x02, 0x01, 0x05,
              0x02, 0x01, 0x03, 0x02, 0x01, 0x01].pack('C*')
    assert_equal(result, c.encode([9,5,3,1]))
    assert_equal([9,5,3,1], c.decode(result))
  end

end
