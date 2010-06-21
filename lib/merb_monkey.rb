if defined?(Merb::Plugins)

  $:.unshift File.dirname(__FILE__)

  dependency 'merb-slices', :immediate => true
  dependency 'merb-assets', :immediate => false
  dependency 'merb-mailer', :immediate => false
  dependency 'dm-aggregates', :immediate => false
  dependency 'excel_loader', :immediate => false
  require 'uploadable.rb'
  require 'monkey_model.rb'
  require 'monkey_property.rb'
  require 'monkey_collection.rb'
  require 'constants.rb'
  
  Merb::Plugins.add_rakefiles "merb_monkey/merbtasks", "merb_monkey/slicetasks", "merb_monkey/spectasks"

  # Register the Slice for the current host application
  Merb::Slices::register(__FILE__)
  
  # Slice configuration - set this in a before_app_loads callback.
  # By default a Slice uses its own layout, so you can swicht to 
  # the main application layout or no layout at all if needed.
  # 
  # Configuration options:
  # :layout - the layout to use; defaults to :merb_monkey
  # :mirror - which path component types to use on copy operations; defaults to all
  Merb::Slices::config[:merb_monkey][:layout] ||= :merb_monkey
  
  # All Slice code is expected to be namespaced inside a module
  module MerbMonkey
    
    # Slice metadata
    self.description = "MerbMonkey is a jQuery-powered admin slice for DataMapper"
    self.version = "0.0.9"
    self.author = "Jon Sarley"
        
    # Stub classes loaded hook - runs before LoadClasses BootLoader
    # right after a slice's classes have been loaded internally.
    def self.loaded
      @@models = {}

      metaclass = class << self; self; end
      metaclass.instance_eval { define_method(:models, lambda { @@models }) }
    end
    
    # Initialization hook - runs before AfterAppLoads BootLoader
    def self.init
    end
    
    # Activation hook - runs after AfterAppLoads BootLoader
    def self.activate
    end
    
    # Deactivation hook - triggered by Merb::Slices.deactivate(MerbMonkey)
    def self.deactivate
    end
    
    # Setup routes inside the host application
    #
    # @param scope<Merb::Router::Behaviour>
    #  Routes will be added within this scope (namespace). In fact, any 
    #  router behaviour is a valid namespace, so you can attach
    #  routes at any level of your router setup.
    #
    # @note prefix your named routes with :merb_monkey_
    #   to avoid potential conflicts with global named routes.
    def self.setup_router(scope)
      scope.match('/').to(:controller => 'main', :action => 'index').name(:home)
      scope.match('/(:action)').to(:controller => 'main')
    end
    
    # Enriches string parameters (like those from a web form)
    # by changing them to more meaningful search options.
    #
    #   MerbMonkey.enrich("royalty" => ">= 100")   #=>  { :royalty.gte => "100" }
    #   MerbMonkey.enrich("name" => "not tom")     #=>  { :name.not => "tom" }
    #
    # And adds a wildcard to the end of a string
    #   MerbMonkey.enrich("name" => "tom")         #=>  { :name.like => "tom%" }
    # 
    # Also, changes "true" and "false" to booleans
    #   MerbMonkey.enrich("alive" => "true")       #=>  { "alive" => true }
    def self.enrich(params)
      obj = {}
      params.each_pair do |key, value|
        orig = value
        value = value.to_s
        next if value.empty?
        if value.match(MerbMonkey::Constants::RE_TRUE)
          obj[key] = true
          next
        end
        if value.match(MerbMonkey::Constants::RE_FALSE)
          obj[key] = false
          next
        end
        if value.match(MerbMonkey::Constants::RE_DIGITS)
          obj[key] = orig
          next            
        end
        oper = value.slice!(MerbMonkey::Constants::RE_OPERATORS).to_s.strip
        if oper == ""
          unless value.match(MerbMonkey::Constants::RE_DATE)
            key = if key.include? "."
              key + ".like"
            else
              key.intern.send(:like)
            end
            value += "%"
          end
        else
          oper = MerbMonkey::Constants::OPERATORS[MerbMonkey::Constants::PASSED.index(oper)]
          key = if key.include? "."
            key + "." + oper
          else
            key.intern.send(oper)
          end
        end
        obj[key] = value.to_s.strip
      end
      obj
    end
    
    class << self
      attr_accessor :authorized_for_create, :authorized_for_read, :authorized_for_update, :authorized_for_delete

      def check(var, controller=nil)
        return true if var.nil?
        var.respond_to?(:call) ? var.call(controller) : var
      rescue => e
        p "Monkey authorization method caused an error, so we're ignoring it."
        p "++++++++++++++++"
        p e.message
        e.backtrace.each { |l| p l }
        p "++++++++++++++++"
        false
      end
      
    end
    
    module Exceptions
      class Unauthorized < StandardError
        def message
          "You are not authorized for this action"
        end
      end
    end
    
    def self.init_for_controller(controller)
      models = controller.params[:model] || controller.params[:models]
      h = {}
      MerbMonkey.models.each do |key, model|
        if models
          next unless models.downcase.split(/,\s*/).include?(key.downcase)
        end
        klass = MerbMonkey.const_get(key)
        m = klass.init_for_controller(controller)
        h[key] = m if m
      end
      h
    end
    
    def self.list(controller)
      params = controller.params
      klass = MerbMonkey.const_get(params[:model])
      raise MerbMonkey::Exceptions::Unauthorized unless klass.authorized_for_read(controller)

      parms = MerbMonkey.enrich(params[:obj])
      parms.merge!(:unique => false) unless parms == {}
      #Send the user in the params if set to true
      if klass.send_user_when_listing && controller && controller.session && controller.session.user
        parms.merge!(:user_id => controller.session.user.attribute_get(:id))
      end

      count = params[:count] == "false" ? nil : klass.count(parms)
      arr = []
      klass.all(parms.merge(:limit => params[:limit].to_i, :offset => params[:offset].to_i)).each do |obj|
        h = {}
        klass.properties.each do |property|
          h[property.name] = obj.send(property.getter)
        end
        arr.push(h)
      end
      { :count => count, :rows => arr }
    end
    
    def self.autocomplete(controller)
      params = controller.params
      model_names = (params[:model] || params[:models]).split(/,\s*/)
      models = {}
      model_names.each do |model_name|
        MerbMonkey.models.map do |name, model|
          models[name] = MerbMonkey.const_get(name).autocomplete if name == model_name
        end
      end
      models
    end
    
    def self.create(controller)
      params = controller.params
      klass = MerbMonkey.const_get(params[:model])
      raise Exceptions::Unauthorized unless klass.authorized_for_create(controller)
      obj = klass.create(params[:obj].except(:id))
      result_hash(obj)
    end
    
    def self.update(controller)
      params = controller.params
      klass = MerbMonkey.const_get(controller.params[:model])
      raise Exceptions::Unauthorized unless klass.authorized_for_update(controller)
      
      obj = klass.get(params[:obj][:id])
      obj.update(params[:obj].except(:id))
      result_hash(obj)
    end
    
    def self.update_all(controller)
      params = controller.params
      klass = MerbMonkey.const_get(controller.params[:model])
      raise Exceptions::Unauthorized unless klass.authorized_for_update(controller)

      obj = klass.get(params[:obj][:id])
      params[:obj].each_pair do |key, val|
        obj.send(key.to_s + "=", val)
      end

      dirty_attrs = {}
      obj.dirty_attributes.each_pair { |k,v| dirty_attrs[k.name] = v }
      
      obj.save
      h = result_hash(obj)
      return h unless obj.save

      # TODO: add run_later support
      #controller.run_later do
        parms = MerbMonkey.enrich(params[:filter])
        klass.all(parms).each { |o| o.update(dirty_attrs) }
      #end
      h
    end
    
    def self.delete(controller)
      params = controller.params
      klass = MerbMonkey.const_get(controller.params[:model])
      raise Exceptions::Unauthorized unless klass.authorized_for_delete(controller)

      obj = klass.get(params[:_id])
      obj.destroy
    end
    
    def self.delete_all(controller)
      params = controller.params
      klass = MerbMonkey.const_get(controller.params[:model])
      raise Exceptions::Unauthorized unless klass.authorized_for_delete(controller)
      
      klass.all(MerbMonkey.enrich(params[:obj])).destroy!
    end
    
    def self.upload(controller)
      params = controller.params
      klass = MerbMonkey.const_get(controller.params[:model])
      
      unless klass.authorized_for_create(controller) && klass.authorized_for_update(controller)
        raise Exceptions::Unauthorized 
      end

      controller.run_later do
        begin
          tempfile = params[:file]["tempfile"]
          path = File.dirname(tempfile.path) + "/" + params[:file]["filename"]
          FileUtils.mv(tempfile.path, path)

          email_settings = {
            :to => MerbMonkey.to_email(controller),
            :from => MerbMonkey.from_email(controller),
            :subject => 'There were no errors in your upload'
          }
          errors = klass.upload(path)
          if errors.empty?
            Merb::Mailer.new(email_settings).deliver!
          else
            email = Merb::Mailer.new(email_settings.merge(
              :subject => "There were errors in the file you uploaded",
              :text => "Please refer to the attached file"
            ))
            email.attach(File.open(ExcelLoader::array_to_file(errors, errors[0].keys | [:errors], path)))
            email.deliver!
          end
        rescue => e
          p e.message
        end
      end
      { :message => "You will receive an email with the results of your upload shortly." }
    end
    
    def self.excel(controller)      
      params = controller.params
      klass = MerbMonkey.const_get(controller.params[:model])
      raise Exceptions::Unauthorized unless klass.authorized_for_read(controller)
      
      parms = MerbMonkey.enrich(params[:obj])
      parms.merge(:limit => 10000)
      #Send the user in the params if set to true
      if klass.send_user_when_listing && controller && controller.session && controller.session.user
        parms.merge!(:user_id => controller.session.user.attribute_get(:id))
      end

      arr = klass.all(parms).to_array_of_hashes
      order = klass.order.map { |property_name| klass.properties[property_name].setter } & arr.first.keys
      file = ExcelLoader::array_to_file(arr, order, Merb.root + "/tmp/" + klass.name + ".xls")
      count = klass.count(parms)
      
      if count > 200
        controller.run_later do
          begin          
            email = Merb::Mailer.new(
              :to => MerbMonkey.to_email(controller),
              :from => MerbMonkey.from_email(controller),
              :subject => "Download",
              :text => "Here's your download"
            )
            email.attach(File.open(file))
            email.deliver!
          rescue => e
            p e.message
          end
        end
        controller.redirect(controller.request.referer, :message => "You will receive an email shortly")
      else
        controller.send_file(file)
      end
    end
    
    def self.to_email(controller=nil)
      self[:to_email].respond_to?(:call) ? self[:to_email].call(controller) : self[:to_email]
    end
    
    def self.from_email(controller=nil)
      self[:from_email].respond_to?(:call) ? self[:from_email].call(controller) : self[:from_email]
    end
    
    private
    def self.result_hash(obj)
      { :error => obj.errors.map { |e| e }.join(" and ") }
    end
    
  end

  Merb::BootLoader.after_app_loads do      
    MerbMonkey.models.each_pair do |name, model|
      MerbMonkey.const_get(name).monkey_callback(model[:block])
    end
  end
  
  Merb::BootLoader.before_app_loads do
    
    module EmptyString
      def to_json
        super.gsub("null", "\"\"")
      end
    end
    class Hash; include EmptyString; end
    
    class DataMapper::Property
      include MonkeyProperty
    end
    
    module DataMapper::Model
      #this actually 'extends' these modules in a model
      include Uploadable
      include MonkeyModel
    end
    
    class DataMapper::Collection
      include MonkeyCollection
    end
    
  end
  
  # Setup the slice layout for MerbMonkey
  #
  # Use MerbMonkey.push_path and MerbMonkey.push_app_path
  # to set paths to merb_monkey-level and app-level paths. Example:
  #
  # MerbMonkey.push_path(:application, MerbMonkey.root)
  # MerbMonkey.push_app_path(:application, Merb.root / 'slices' / 'merb_monkey')
  # ...
  #
  # Any component path that hasn't been set will default to MerbMonkey.root
  #
  # Or just call setup_default_structure! to setup a basic Merb MVC structure.
  MerbMonkey.setup_default_structure!
  
  # Add dependencies for other MerbMonkey classes below. Example:
  # dependency "merb_monkey/other"
  
end