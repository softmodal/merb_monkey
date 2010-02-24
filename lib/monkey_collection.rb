module MonkeyCollection
    
  def to_array_of_hashes
    arr = []
    self.each do |obj|
      h = {}
      klass = obj.class
      klass.order.each do |property_name|
        property = klass.properties[property_name]
        h[property.setter] = obj.send(property.getter) if !property.hide or property.serial?
      end
      arr << h
    end
    arr
  end

end
