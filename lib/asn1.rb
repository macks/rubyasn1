# $Id: asn1.rb 95 2006-06-20 15:57:46Z mks $
# Copyright (C) 2005 MATSUYAMA Kengo <macksx@gmail.com>. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the GNU General Public License version 2, or any later version.

module ASN1
end

require 'asn1/constants'
require 'asn1/static_functions'
require 'asn1/converter'
require 'asn1/type'

system "racc #{srcdir_root + '/rubyasn1.y'} -o parser.rb" or raise
require 'asn1/parser'

require 'asn1/encoder'
require 'asn1/decoder'

if $0 == __FILE__
  require 'pp'
  p = ASN1::Parser.new
  if c = p.parse(ARGF.read)
    pp c
  else
    pp p.error, p.backtrace
  end
end
