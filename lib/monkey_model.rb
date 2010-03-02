module MonkeyModel
  attr_writer :order, :label_singular, :label_plural, :identified_by, 
    :authorized_for_create, :authorized_for_read, :authorized_for_update, :authorized_for_delete
  
  def authorized_for_create(controller=nil)
    auth = @authorized_for_create
    auth = auth.nil? ? MerbMonkey.authorized_for_create : auth
    MerbMonkey.check(auth, controller)
  end
  
  def authorized_for_read(controller=nil)
    auth = @authorized_for_read
    auth = auth.nil? ? MerbMonkey.authorized_for_read : auth
    MerbMonkey.check(auth, controller)
  end
  
  def authorized_for_update(controller=nil)
    auth = @authorized_for_update
    auth = auth.nil? ? MerbMonkey.authorized_for_update : auth
    MerbMonkey.check(auth, controller)
  end
  
  def authorized_for_delete(controller=nil)
    auth = @authorized_for_delete
    auth = auth.nil? ? MerbMonkey.authorized_for_delete : auth
    MerbMonkey.check(auth, controller)
  end
  
  def order
    if @order
      @order.unshift(:id) unless @order.include?(:id)
    end
    @order || self.properties.map { |prop| prop.name }
  end
  
  def label_singular
    @label_singular || self.name
  end
  
  def label_plural
    @label_plural || self.name.pluralize
  end

  def identified_by
    @identified_by || (_properties.include?(:name) ? :name : :id)
  end
  
  def autocomplete
    field = self.identified_by
    # If field is a property, we sort it in the db for speed
    if _properties.include?(field)
      self.all(:order => field).map { |o| o.send(field) }
    # otherwise we sort it afterwards
    else
      self.all.map { |o| o.send(field) }.sort
    end
  end
  
  def monkey(&blk)
    MerbMonkey.models[self.name] = { :block => blk }
  end
  
  def monkey_callback(blk)
    class_eval { define_method(:identified_as, lambda { self.send(self.class.send(:identified_by)) }) }
    class_eval { define_method(:errors, lambda { 
      return unless defined?(super)
      hash = super
      return hash unless @_errors
      @_errors.each_pair do |k,v|
        hash[k] = [v]
      end
      hash.delete(:__validator)
      hash
    }) }

    init_relationship_defaults
    blk.call(self, self.properties) if blk
  end

  def init_for_controller
    return nil unless authorized_for_read
    h = {
      :authorized_for_create => authorized_for_create(nil),
      :authorized_for_update => authorized_for_update(nil),
      :authorized_for_delete => authorized_for_delete(nil),
      :label => {
        :singular => label_singular,
        :plural => label_plural
      },
      :identified_by => identified_by,
      :order => order,
      :properties => {}
    }
    properties.each do |property|
      h[:properties][property.name] = property.init_for_controller
    end
    h
  end
  
  private
  def _properties
    self.properties.map { |prop| prop.name }
  end
  
  def init_relationship_defaults
    self.relationships.each do |name, relationship|
      next unless relationship.class == DataMapper::Associations::ManyToOne::Relationship
      getter = setter = "__#{relationship.name}__"
      model_class = relationship.parent_key.map { |prop| prop.model }.first
      property = relationship.child_key.first

      # Create getter method for parent model relationship that returns a string
      class_eval { define_method(getter, lambda { 
        self.send(relationship.name).identified_as rescue nil 
      }) }
      
      # Create a setter method for the parent model relationship that takes a string
      class_eval { define_method("#{setter}=", lambda { |val|
        if relationship.required? == false and val.to_s.empty?
          self.send("#{relationship.name}=", nil)
        else
          instances = model_class.all(model_class.identified_by.like => val)              
          msg = if instances.length > 1
            "Multiple #{model_class.name.pluralize} found with #{model_class.identified_by}: #{val}"
          elsif instances.length == 0
            "No #{model_class.name} was found with #{model_class.identified_by}: #{val}"
          end

          if msg
            @_errors = @_errors || {} 
            @_errors[property.name] = msg
            self.send("#{relationship.name}=", nil)
          else
            self.send("#{relationship.name}=", instances.first)
          end
        end
      }) }
      
      # Change the parameters for this property since it's a relationship
      property.type = :relationship
      property.autocomplete = relationship.parent_model
      property.header = name.camel_case
      property.getter = getter
      property.setter = setter
      property.finder = lambda { "#{model_class.name.snake_case}.#{model_class.send(:identified_by)}" }
    end
  end
end