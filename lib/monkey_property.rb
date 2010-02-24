module MonkeyProperty
  attr_writer :hide, :hide_in_index, :readonly, :header, :getter, :setter, :finder
  attr_accessor :type
  
  def hide
    return @hide unless @hide.nil?
    self.serial? ? true : false
  end
  
  def hide_in_index
    return @hide_in_index unless @hide_in_index.nil?
    self.serial? ? true : false
  end
  
  def readonly
    return @readonly unless @readonly.nil?
    self.serial? ? true : false
  end
  
  def header
    @header || field.to_s.camel_case
  end

  def getter
    @getter || field.to_s.snake_case
  end

  def setter
    @setter || field.to_s.snake_case
  end

  def finder
    @finder || field.to_s.snake_case
  end
  
  def required
    !self.allow_nil?
  end
  
  def html_element_type
    return :serial if self.serial?
    return :checkbox if self.type == DataMapper::Types::Boolean
    return :textarea if self.type == DataMapper::Types::Text
    return :relationship if self.type == :relationship
    :input
  end
  
  def init_for_controller
    find = finder.respond_to?(:call) ? finder.call : finder
    {
      :type => html_element_type,
      :hide => hide,
      :hide_in_index => hide_in_index,
      :required => required,
      :readonly => readonly,
      :header => header,
      :finder => find,
      :setter => setter,
      :getter => getter
    }
  end
end