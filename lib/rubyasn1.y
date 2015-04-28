# $Id: rubyasn1.y 84 2005-12-26 11:06:10Z mks $
# Copyright (C) 2005 MATSUYAMA Kengo <macksx@gmail.com>. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the GNU General Public License version 2, or any later version.

# BNF description is borrowed from Convert::ASN1 module for Perl.
# Convert::ASN1 is copyrighted by Graham Barr <gbarr@pobox.com>.

class ASN1::Parser

  token WORD
  token CLASS
  token SEQUENCE
  token SET
  token CHOICE
  token OF
  token IMPLICIT
  token EXPLICIT
  token OPTIONAL
  token LBRACE
  token RBRACE
  token COMMA
  token ANY
  token ASSIGN
  token NUMBER
  token ENUM
  token COMPONENTS
  token POSTRBRACE
  token DEFINED
  token BY

rule

  top: slist          { result = { '' => val[0] } }
     | module
     ;

  module: WORD ASSIGN aitem         { result = { val[0] => [val[2]] } }
        | module WORD ASSIGN aitem  { result[val[1]] = [val[3]] }
        ;

  aitem: class plicit anyelem postrb
          {
            val[2].tag = val[0]
            result = val[2]
            result.tag_explicit! if val[1]
          }
       | celem
       ;

  anyelem: onelem
         | eelem
         | oelem
         | selem
         ;

  celem: COMPONENTS OF WORD
          {
            result = ASN1Type.new( :type  => val[0], :child => val[2] )
          }
       ;

  seqset: SEQUENCE
        | SET
        ;

  selem: seqset OF class plicit sselem optional
          {
            val[4].tag = val[2]
            result = ASN1Type.new(
              :type  => val[0],
              :child => [val[4]],
              :loop  => true,
              :optional => val[5]
            )
            result.tag_explicit! if val[3]
          }
       ;

  sselem: eelem
        | oelem
        | onelem
        ;

  onelem: SEQUENCE LBRACE slist RBRACE
            {
              result = ASN1Type.new( :type => val[0], :child => val[2] )
            }
        | SET      LBRACE slist RBRACE
            {
              result = ASN1Type.new( :type => val[0], :child => val[2] )
            }
        | CHOICE   LBRACE nlist RBRACE
            {
              result = ASN1Type.new( :type => val[0], :child => val[2] )
            }
        ;

  eelem: ENUM LBRACE elist RBRACE   { result = ASN1Type.new( :type => 'ENUM' ) }

  oielem: WORD        { result = ASN1Type.new( :type => val[0] ) }
        | SEQUENCE    { result = ASN1Type.new( :type => val[0] ) }
        | SET         { result = ASN1Type.new( :type => val[0] ) }
        | ANY defined
            {
              result = ASN1Type.new(
                :type  => val[0], 
                :child => [],
                :def_by => val[1]
              )
            }
        | ENUM        { result = ASN1Type.new( :type => val[0] ) }
        ;

  defined: /* none */         { result = nil }
         | DEFINED BY WORD    { result = val[2].gsub(/-/, '_').intern }
         ;

  oelem: oielem
       ;

  nlist: nlist1
       | nlist1 POSTRBRACE
       ;

  nlist1: nitem                     { result = [val[0]] }
        | nlist1 POSTRBRACE nitem   { result.push val[2] }
        | nlist1 COMMA nitem        { result.push val[2] }
        ;

  nitem: varname class plicit anyelem
          {
            result = val[3]
            result.name = val[0]
            result.tag  = val[1]
            result.tag_explicit! if val[2]
          }
       ;

  slist: slist1
       | slist1 POSTRBRACE
       ;

  slist1: sitem                     { result = [val[0]] }
        | slist1 COMMA sitem        { result.push val[2] }
        | slist1 POSTRBRACE sitem   { result.push val[2] }
        ;

  snitem: oelem optional  { result.optional = val[1] }
        | eelem
        | selem
        | onelem
        ;

  sitem: varname class plicit snitem
          {
            result = val[3]
            result.name = val[0]
            result.tag  = val[1]
            result.tag_explicit! if val[2]
          }
       | celem
       | class plicit onelem
          {
            result = val[2]
            result.tag = val[0]
            result.tag_explicit! if val[1]
          }
       ;

  varname: WORD           { result = val[0].gsub(/-/, '_').intern }
         ;

  optional: /* none */    { result = false }
          | OPTIONAL      { result = true }
          ;

  class: /* none */       { result = nil }
       | CLASS
       ;

  plicit: /* none */      { result = false }
        | EXPLICIT        { result = true }
        | IMPLICIT        { result = false }
        ;

  /* @todo: implement enum */
  elist: eitem
       | elist COMMA eitem 
       ;

  eitem: WORD NUMBER
       ;

  postrb: /* none */
        | POSTRBRACE
        ;

end

---- header

require 'strscan'

---- inner

  RESERVED_WORDS = {
    'OPTIONAL'    => :OPTIONAL,
    'CHOICE'      => :CHOICE,
    'OF'          => :OF,
    'IMPLICIT'    => :IMPLICIT,
    'EXPLICIT'    => :EXPLICIT,
    'SEQUENCE'    => :SEQUENCE,
    'SET'         => :SET,
    'ANY'         => :ANY,
    'ENUM'        => :ENUM,
    'ENUMERATED'  => :ENUM,
    'COMPONENTS'  => :COMPONENTS,
    '{'           => :LBRACE,
    '}'           => :RBRACE,
    ','           => :COMMA,
    '::='         => :ASSIGN,
    'DEFINED'     => :DEFINED,
    'BY'          => :BY
  }

  TAG_CLASSES = {
    'APPLICATION' => CLASS_APPLICATION,
    'UNIVERSAL'   => CLASS_UNIVERSAL,
    'PRIVATE'     => CLASS_PRIVATE,
    'CONTEXT'     => CLASS_CONTEXT,
    ''            => CLASS_CONTEXT  # if not specified, it's CONTEXT
  }

  REGEXP_PATTERN = /(?:
    (\s+|--[^\n]*)
    | ([,{}]|::=)
    | (#{RESERVED_WORDS.keys.grep(/\w/).sort.join('|')})\b
    | ( (?:OCTET|BIT)\s+STRING
      | OBJECT\s+IDENTIFIER
      | RELATIVE-OID
      )\b
    | (\w+(?:-\w+)*)
    | \[\s* (
        (?:(?:APPLICATION|PRIVATE|UNIVERSAL|CONTEXT)\s+)?
        \d+
      ) \s*\]
    | \((\d+)\)
  )/mxo

  BASE_TYPES = {
    'BOOLEAN'           => [ TAG_BOOLEAN.chr,           :opBOOLEAN ],
    'INTEGER'           => [ TAG_INTEGER.chr,           :opINTEGER ],
    'BIT_STRING'        => [ TAG_BIT_STRING.chr,        :opBITSTR  ],
    'OCTET_STRING'      => [ TAG_OCTET_STRING.chr,      :opSTRING  ],
    'STRING'            => [ TAG_OCTET_STRING.chr,      :opSTRING  ],
    'NULL'              => [ TAG_NULL.chr,              :opNULL    ],
    'OBJECT_IDENTIFIER' => [ TAG_OBJECT_IDENTIFIER.chr, :opOBJID   ],
    'REAL'              => [ TAG_REAL.chr,              :opREAL    ],
    'ENUMERATED'        => [ TAG_ENUMERATED.chr,        :opINTEGER ],
    'ENUM'              => [ TAG_ENUMERATED.chr,        :opINTEGER ],
    'RELATIVE-OID'      => [ TAG_RELATIVE_OID.chr,      :opROID    ],

    'SEQUENCE' => [ (TAG_SEQUENCE | TAG_CONSTRUCTIVE).chr, :opSEQUENCE ],
    'SET'      => [ (TAG_SET      | TAG_CONSTRUCTIVE).chr, :opSET ],

    'ObjectDescriptor'  => [ TAG_OBJECT_DESCRIPTOR.chr, :opSTRING ],
    'UTF8String'        => [ TAG_UTF8_STRING.chr,       :opSTRING ],
    'NumericString'     => [ TAG_NUMERIC_STRING.chr,    :opSTRING ],
    'PrintableString'   => [ TAG_PRINTABLE_STRING.chr,  :opSTRING ],
    'TeletexString'     => [ TAG_TELETEX_STRING.chr,    :opSTRING ],
    'T61String'         => [ TAG_TELETEX_STRING.chr,    :opSTRING ],
    'VideotexString'    => [ TAG_VIDEOTEX_STRING.chr,   :opSTRING ],
    'IA5String'         => [ TAG_IA5_STRING.chr,        :opSTRING ],
    'UTCTime'           => [ TAG_UTC_TIME.chr,          :opUTIME ],
    'GeneralizedTime'   => [ TAG_GENERALIZED_TIME.chr,  :opGTIME ],
    'GraphicString'     => [ TAG_GRAPHIC_STRING.chr,    :opSTRING ],
    'VisibleString'     => [ TAG_VISIBLE_STRING.chr,    :opSTRING ],
    'ISO646String'      => [ TAG_VISIBLE_STRING.chr,    :opSTRING ],
    'GeneralString'     => [ TAG_GENERAL_STRING.chr,    :opSTRING ],
    'CharacterString'   => [ TAG_CHARACTER_STRING.chr,  :opSTRING ],
    'UniversalString'   => [ TAG_CHARACTER_STRING.chr,  :opSTRING ],
    'BMPString'         => [ TAG_BMP_STRING.chr,        :opSTRING ],
    'BCDString'         => [ TAG_OCTET_STRING.chr,      :opBCD ],

    'CHOICE' => [ nil, :opCHOICE ],
    'ANY'    => [ nil, :opANY ],
  }

  attr_reader :error, :backtrace

  def parse(str)
    @scanner = StringScanner.new(str)
    @stack = []
    @lastpos = 0
    @pos = 0

    tree = nil
    begin
      tree = compile(verify(do_parse))
    rescue ASN1Error, Racc::ParseError => e
      @error = e.to_s
      @backtrace = e.backtrace
      return nil
    end

    return ASN1Converter.new(tree)
  end

  def next_token
    return @stack.shift unless @stack.empty?

    while (token = @scanner.scan(REGEXP_PATTERN))
      if @scanner[1]
        next  # comment or whitespace
      elsif @scanner[2] || @scanner[3]
        # A comma is not required after a '}' so to aid the
        # parser we insert a fake token after any '}'
        @stack.push [:POSTRBRACE, ''] if token == '}'
        return [RESERVED_WORDS[token], token]
      elsif @scanner[4]
        return [:WORD, token.gsub(/\s+/, '_')]
      elsif @scanner[5]
        return [:WORD, token]
      elsif @scanner[6]
        tag_class, num = /^([A-Z]*)\s*(\d+)$/.match(@scanner[6]).captures
        tag = ASN1.encode_tag(TAG_CLASSES[tag_class], num.to_i)
        return [:CLASS, tag]
      elsif @scanner[7]
        return [:NUMBER, @scanner[7]]
      end

      raise 'Internal error'
    end

    return nil if @scanner.eos?

    raise ASN1Error, "Parse error before #{@scanner.string.slice(@scanner.pos, 40)}"
  end

  def verify(tree)
    # Well it parsed correctly, now we
    #  - check references exist
    #  - flatten COMPONENTS OF (checking for loops)
    #  - check for duplicate var names

    tree.each do |name, ops|
      stash = {}
      scope = []
      path = ''
      idx = 0

      while true
        if idx < ops.size
          op = ops[idx]
          idx += 1
          if op.name
            raise ASN1Error, "#{name}: #{path}.#{op.name} used multiple times." if stash[op.name]
            stash[op.name] = true
          end
          if op.child
            if op.child.is_a?(Array)
              scope.push [stash, path, ops, idx]
              if op.name
                stash = {}
                path += ".#{op.name}"
              end
              idx = 0
              ops = op.child
            elsif op.type == 'COMPONENTS'
              idx -= 1
              ops[idx, 1] = expand_ops(tree, op.child)
            else
              raise 'Internal error.'
            end
          end
        else
          break if scope.empty?
          stash, path, ops, idx = scope.pop
        end
      end
    end
    return tree
  end

  def expand_ops(tree, want, seen = {})
    raise ASN1Error, "COMPONENTS OF loop #{want}" if seen[want]
    raise ASN1Error, "Undefined macro #{want}" unless tree.has_key?(want)
    seen[want] = true
    ops = tree[want]
    if ops.size == 1 && (ops[0].type == 'SEQUENCE' || ops[0].type == 'SET') && ops[0].child.is_a?(Array)
      ops = ops[0].child 
      idx = 0
      while idx < ops.size
        op = ops[idx]
        if op.type == 'COMPONENTS'
          ops[idx, 1] = expand_ops(tree, op.child, seen)
        else
          idx += 1
        end
      end
    else
      raise ASN1Error, "Bad macro COMPONENTS OF '#{want}'"
    end
    return ops
  end

  def compile(tree)
    # The tree should be valid enough to be able to
    #  - resolve references
    #  - encode tags
    #  - verify CHOICEs do not contain duplicate tags

    tree.each do |name, ops|
      compile_one(tree, ops, name)
    end
    return tree
  end

  def compile_one(tree, ops, name)
    ops.each do |op|
      next if op.type.is_a?(Symbol)  # skip if already compiled
      type = op.type
      if BASE_TYPES[type]
        op.tag ||= BASE_TYPES[type][0]
        op.type  = BASE_TYPES[type][1]
      else
        raise ASN1Error, "Unknown type '#{type}'" unless tree[type]
        ref = compile_one(tree, tree[type], op.name ? "#{name}.#{op.name}" : name)
        op.tag ||= ref[0].tag
        op.type  = ref[0].type
        op.child = ref[0].child
        op.loop  = ref[0].loop
      end
      op.tag_constructive! if op.type == :opSET || op.type == :opSEQUENCE

      if op.child
        # If we have children we are one of
        #  opSET opSEQUENCE opCHOICE
        compile_one(tree, op.child, op.name ? "#{name}.#{op.name}" : name)

        # If a CHOICE is given a tag, then it must be EXPLICIT
        if op.type == :opCHOICE && op.tag
          op.tag_explicit!
          op.tag_constructive!
          op.type = :opSEQUENCE
        end

        if op.child.size > 1
          #if ($op->[cTYPE] != opSEQUENCE) {
          # Here we need to flatten CHOICEs and check that SET and CHOICE
          # do not contain duplicate tags
          #}
          if op.type == :opSET
            # In case we do CER encoding we order the SET elements by thier tags
            op.child = op.child.sort_by do |c|
              c.tag || (c.type == :opCHOICE ? c.child.map { |cc| cc.tag }.min : '')
            end
          end
        else
          # A SET of one element can be treated the same as a SEQUENCE
          op.type = :opSEQUENCE if op.type == :opSET
        end
      end
    end
    return ops
  end

---- footer
