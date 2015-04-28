module ASN1
  class ASN1Type

    attr_accessor :name, :tag, :type, :child, :loop, :optional, :def_by

    def initialize(arg = {})
      @name = arg[:name] if arg[:name]
      @tag  = arg[:tag]  if arg[:tag]
      @type = arg[:type] if arg[:type]
      @child = arg[:child] if arg[:child]
      @def_by = arg[:def_by] if arg[:def_by]
      @loop = arg[:loop] || false
      @optional = arg[:optional] || false
    end

    def members
      if @name
        @name
      elsif ! @child.is_a?(Array) || @child.empty?
        nil
      elsif @child.size == 1
        @child[0].members
      else
        @child.map {|c| c.name}
      end
    end

    def tag_explicit!
      new_op = ASN1Type.new(
        :type  => self.type,
        :child => self.child,
        :loop  => self.loop,
        :optional=> false
      )
      self.type  = 'SEQUENCE'
      self.child = [new_op]
      self.loop  = false
      return self
    end

    def tag_constructive!
      if self.tag && self.tag[0] & ASN1::TAG_CONSTRUCTIVE == 0
        self.tag[0] |= ASN1::TAG_CONSTRUCTIVE
      end
    end

  end # class ASN1Type
end