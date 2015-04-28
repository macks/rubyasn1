module ASN1
  # ASN.1 tag values
  TAG_BOOLEAN           = 0x01
  TAG_INTEGER           = 0x02
  TAG_BIT_STRING        = 0x03
  TAG_OCTET_STRING      = 0x04
  TAG_NULL              = 0x05
  TAG_OBJECT_IDENTIFIER = 0x06
  TAG_OBJECT_DESCRIPTOR = 0x07
  TAG_EXTERNAL          = 0x08
  TAG_REAL              = 0x09
  TAG_ENUMERATED        = 0x0a
  TAG_UTF8_STRING       = 0x0c
  TAG_RELATIVE_OID      = 0x0d
  TAG_SEQUENCE          = 0x10
  TAG_SET               = 0x11
  TAG_NUMERIC_STRING    = 0x12
  TAG_PRINTABLE_STRING  = 0x13
  TAG_TELETEX_STRING    = 0x14
  TAG_VIDEOTEX_STRING   = 0x15
  TAG_IA5_STRING        = 0x16
  TAG_UTC_TIME          = 0x17
  TAG_GENERALIZED_TIME  = 0x18
  TAG_GRAPHIC_STRING    = 0x19
  TAG_VISIBLE_STRING    = 0x1a
  TAG_GENERAL_STRING    = 0x1b
  TAG_CHARACTER_STRING  = 0x1c
  TAG_BMP_STRING        = 0x1e

  # ASN.1 tag classes
  CLASS_UNIVERSAL       = 0x00
  CLASS_APPLICATION     = 0x40
  CLASS_CONTEXT         = 0x80
  CLASS_PRIVATE         = 0xc0

  # primitive or constructive
  TAG_PRIMITIVE         = 0x00
  TAG_CONSTRUCTIVE      = 0x20
end