require File.dirname(__FILE__) + '/spec_helper'

describe "DataMapper::Property" do
    
  before(:all) do
    class Author; property :home_town, String; end
    @name = Author.properties[:name]
    @hometown = Author.properties[:home_town]
  end
  
  it "hide should return false by default" do
    @name.hide.should == false
  end

  it "hide_in_index should return false by default" do
    @name.hide_in_index.should == false
  end

  it "readonly should return false by default" do
    @name.readonly.should == false
  end
  
  it "header should return the camel_cased name of the field by default" do
    @hometown.header.should == "HomeTown"
  end
  
  it "getter should return the snake_cased name of the field by default" do
    @hometown.getter.should == "home_town"
  end

  it "setter should return the snake_cased name of the field by default" do
    @hometown.setter.should == "home_town"
  end

  it "finder should return the snake_cased name of the field by default" do
    @hometown.finder.should == "home_town"
  end
  
  it "required should return the opposite of allow_nil?" do
    @name.allow_nil?.should == !@name.required
    @hometown.allow_nil?.should == !@hometown.required
    Author.properties[:id].allow_nil?.should == !Author.properties[:id].required
  end

  describe "html_element_type" do

    it "should return serial if the property is a serial" do
      Author.properties[:id].html_element_type.should == :serial
    end
    
    it "should return checkbox if the property is a boolean" do
      Author.properties[:alive].html_element_type.should == :checkbox
    end
    
    it "should return textarea if the property is text" do
      Book.properties[:notes].html_element_type.should == :textarea
    end

    it "should return an input otherwise" do
      Author.properties[:name].html_element_type.should == :input
    end

  end
  
  describe "init_for_controller" do
    
    before(:all) do
      @hash = Author.properties[:name].init_for_controller
    end
    
    it "should return a hash" do
      @hash.class.should == Hash
    end
    
    it "should include the type of HTML element" do
      @hash[:type].should == :input
    end

    it "should include whether to hide the property" do
      @hash[:hide].should == false
    end

    it "should include whether to hide the property in index" do
      @hash[:hide_in_index].should == false
    end

    it "should include whether the property is required" do
      @hash[:required].should == false
    end

    it "should include whether the property is readonly" do
      @hash[:readonly].should == false
    end

    it "should include the header of the property" do
      @hash[:header].should == "Name"
    end

    it "should include the finder method of the property" do
      @hash[:finder].should == "name"
    end
    
    it "should send call to the finder if it is a lambda" do
      Author.properties[:name].finder = lambda { true }
      Author.properties[:name].init_for_controller[:finder].should == true
    end

    it "should include the getter method of the property" do
      @hash[:getter].should == "name"
    end

    it "should include the setter method of the property" do
      @hash[:setter].should == "name"
    end
        
  end

end

describe "DataMapper::Model" do

  describe "init_relationship_defaults" do

    before(:all) do
      Author.send(:init_relationship_defaults)
      @author = Author.first
      Book.send(:init_relationship_defaults)
      @book = Book.first
    end

    describe "adding a getter method" do

      it "should add a method" do
        @book.should respond_to(:__author__)
      end
      
      it "should return a string" do
        @book.__author__.class.should == String
      end
      
      it "should return the identified_by field on the parent model" do
        @book.__author__.should == "Tom Clancy"
      end

    end
    
    describe "adding a setter method" do

      it "should add a method" do
        @book.should respond_to(:__author__=)
      end
      
      it "should take a string" do
        lambda {
          @book.__author__ = "Tom Clancy"
        }.should_not raise_error
      end

      describe "if the parameter is an empty string" do

        it "should set the relationship to nil if the property is not required" do
          @author.__publisher__ = ""
          @author.save.should == true
          @author.publisher.should == nil
        end
        
        it "should not save if the property is required" do
          @book.__author__ = ""
          @book.save.should == false
        end

      end

      it "should be case insensitive" do
        @book.__author__ = "tom clancy"
        @book.save.should == true
        @book.author.should == Author.first(:name => "Tom Clancy")
      end

      it "should add a validation error if the parent model lookup results in multiple instances" do
        a = Author.create(:name => "Tom Clancy")
        @book.__author__ = "tom clancy"
        @book.save.should == false
        @book.errors[:author_id].should == ["Multiple Authors found with name: tom clancy"]
        a.destroy
      end
      
      it "should add a validation error if the parent model lookup results in zero instances" do
        @book.__author__ = "nonsense"
        @book.save.should == false
        @book.errors[:author_id].should == ["No Author was found with name: nonsense"]
      end

    end
    
    describe "changing the parameters for the property of a relationship" do

      before(:all) do
        @property = Book.properties[:author_id]
      end

      it "should set the header to the parent model's name by default" do
        @property.header.should == "Author"
      end
      
      it "should change the type to :relationship" do
        @property.type.should == :relationship
        @property.html_element_type.should == :relationship
      end
      
      it "should change getter to the getter method symbol" do
        @property.getter.should == "__author__"
      end

      it "should change setter to the setter method symbol" do
        @property.setter.should == "__author__"
      end
      
      it "should change finder to a lambda that calls the parent model's identified_by" do
        @property.finder.class.should == Proc
        @property.finder.call().should == "author.name"
      end

    end
    
    describe "id property" do

      before(:all) do
        @id = Author.properties[:id]
      end

      it "should set hide to true by default" do
        @id.hide.should == true
      end
      
      it "should set hide_in_index to true by default" do
        @id.hide_in_index.should == true
      end
      
      it "should set readonly to true by default" do
        @id.readonly.should == true
      end

    end
    
    it "should only work on ManyToOne relationships" do
      class Author; has n, :books; end;
      Book.send(:init_relationship_defaults)
      Author.send(:init_relationship_defaults)
      Book.properties[:author_id].getter.should == "__author__"
    end
  
  end

  describe "order" do

    it "should default to the order of the properties" do
      Book.order.should == [:id, :title, :published, :notes, :royalty, :author_id]
    end

    it "should prepend the :id field if it's left out" do
      Book.order = [:title, :author_id]
      Book.order.should == [:id, :title, :author_id]
    end

  end
  
  describe "label_singular" do
    
    it "should default to the name of model" do
      Book.label_singular.should == "Book"
    end
    
  end

  describe "label_plural" do
    
    it "should default to the name of model" do
      Book.label_plural.should == "Books"
    end
    
  end
  
  describe "identified_by" do

    it "should default to :name if there is a name field" do
      Author.identified_by.should == :name
    end
    
    it "should default to :id if there is not a name field" do
      class Distributor; include DataMapper::Resource; property :id, Serial; end
      Distributor.identified_by.should == :id
    end

  end

  describe "autocomplete" do

    it "should return an array of model instances" do
      Author.autocomplete.class.should == Array
    end

    it "should order the array by the identified_by field" do
      Book.identified_by = :title
      Book.autocomplete.should == ["Post Captain", "The Hunt for Red October", "The Ionian Mission"]
    end
    
    it "should work even if :identified_by isn't a property" do
      class Book
        def _title
          "#{self.title} - #{self.id}"
        end
      end
      Book.identified_by = :_title
      Book.create(:title => "Post Captain", :author_id => 2)
      books = ["Post Captain - 2", "Post Captain - 4", "The Hunt for Red October - 1", "The Ionian Mission - 3"]
      Book.autocomplete.should == books
      Book.identified_by = :title
    end

  end

  describe "init_for_controller" do

    before(:all) do
      @hash = Author.init_for_controller(@controller)
    end
    
    it "should return nil if the model is not authorized for read" do
      Author.authorized_for_read = false
      Author.init_for_controller(@controller).should == nil
      Author.authorized_for_read = true
    end
    
    it "should return a hash" do
      @hash.class.should == Hash
    end

    it "should include whether or not an instance can be created" do
      @hash[:authorized_for_create] = true 
    end

    it "should include whether or not an instance can be created" do
      @hash[:authorized_for_update] = true 
    end

    it "should include whether or not an instance can be created" do
      @hash[:authorized_for_delete] = true 
    end
    
    it "should include the singular label" do
      @hash[:label][:singular].should == "Author"
    end

    it "should include the plural label" do
      @hash[:label][:plural].should == "Authors"
    end
    
    it "should include the identified_by field" do
      @hash[:identified_by].should == :name
    end

    it "should include the order" do
      @hash[:order].should == [:id, :name, :alive, :publisher_id, :home_town]
    end
    
    it "should include the initialization for each of its properties" do
      @hash = Author.init_for_controller(@controller)
      Author.properties.each do |property|
        @hash[:properties][property.name].should == property.init_for_controller
      end
    end

  end

end

describe "MerbMonkey (module)" do
  
  before(:all) do
    class Kontroller
      def initialize
        @params = { :obj => {}, :count => "false", :limit => 10, :offset => 0 }
      end
      def run_later; yield; end
      def params; @params; end
    end
    @controller = Kontroller.new
  end
  
  describe "list" do

    before(:all) do
      class Kontroller
        def initialize
          @params = {
            :obj => {},
            :count => "false",
            :limit => 10,
            :offset => 0,
            :model => "Author"
          }
        end
        def params
          @params
        end
      end
      @controller = Kontroller.new
      Author.authorized_for_read = true
    end

    it "should return a hash" do
      MerbMonkey.list(@controller).class.should == Hash
    end

    it "should raise an Unauthorized error if authorized_for_read is false for the model" do
      Author.authorized_for_read = false
      lambda { MerbMonkey.list(@controller) }.should raise_error(MerbMonkey::Exceptions::Unauthorized)
      Author.authorized_for_read = true
    end
    
    it "should return nil for count if params['count'] is false" do
      MerbMonkey.list(@controller)[:count].should == nil
    end

    it "should return the count if params[:count] is any other value"
    
    it "should return an array of hashes representing instances of that model" do
      @controller.params[:obj] = { "name" => "tom" }
      rows = MerbMonkey.list(@controller)[:rows]
      rows.class.should == Array
      rows.first[:name].should == "Tom Clancy"
    end

  end
  
  describe "autocomplete" do

    before(:all) do
      @controller.params[:models] = "Author, Publisher"
      @h = MerbMonkey.autocomplete(@controller)
    end

    it "should return a hash of arrays" do
      @h.class.should == Hash
      @h.first.class.should == Array
    end

    it "should return all the models that are passed into the :models parameter" do
      @h.size.should == 2
      @h.keys.sort.should == %w{Author Publisher}
    end

    it "should return only the model passed in the :model parameter" do
      @controller.params[:models] = "Book"
      h = MerbMonkey.autocomplete(@controller)
      h.keys.should == ["Book"]
    end
    
  end
  
  describe "create" do

    it "should raise an unauthorized error if the model isn't authorized_for_create" do
      Author.authorized_for_create = false
      @controller.params[:model] = "Author"
      lambda { MerbMonkey.create(@controller) }.should raise_error(MerbMonkey::Exceptions::Unauthorized)
      Author.authorized_for_create = true
    end
    
    it "should create an instance of an object" do
      @controller.params[:obj] = { :name => "John LeCarre" }
      sz = Author.all.size
      MerbMonkey.create(@controller)
      authors = Author.all
      sz.should < authors.size
      authors.last.name.should == "John LeCarre"
    end
    
    it "should return a hash with an :error key" do
      MerbMonkey.create(@controller)[:error].should == ""
    end
    
  end
  
  describe "update" do

    it "should raise an unauthorized errror if the model isn't authorized_for_update" do
      Author.authorized_for_update = false
      @controller.params[:model] = "Author"
      lambda { MerbMonkey.update(@controller) }.should raise_error(MerbMonkey::Exceptions::Unauthorized)
      Author.authorized_for_update = true      
    end
    
    it "should update an instance of an object" do
      sz = Author.all.size
      @controller.params[:obj] = { :name => "John Grisham", :id => sz + 1}
      MerbMonkey.update(@controller)
      authors = Author.all
      authors.size.should == sz
      authors.last.name.should == "John Grisham"
    end

    it "should return a hash with an :error key" do
      MerbMonkey.update(@controller)[:error].should == ""
    end
    
  end
  
  describe "update_all" do

    it "should raise an unauthorized errror if the model isn't authorized_for_update" do
      Author.authorized_for_update = false
      @controller.params[:model] = "Author"
      lambda { MerbMonkey.update_all(@controller) }.should raise_error(MerbMonkey::Exceptions::Unauthorized)
      Author.authorized_for_update = true      
    end
    
    it "should update all instances that share the :filter parameters" do
      Author.all(:name.like => "john%").each { |a| a.alive = true; a.save }
      @controller.params[:filter] = { "name" => "john" }
      @controller.params[:obj] = { "alive" => "false", :id => Author.all.last.attribute_get(:id) }
      MerbMonkey.update_all(@controller)
      Author.all(:name.like => "john%").each { |a| a.alive.should == false }
    end
    
    it "should return a hash with an :error key" do
      MerbMonkey.update_all(@controller).should == { :error => "" }      
    end
    
    it "should return a hash with validations errors if the original model couldn't save" do
      @controller.params[:obj] = { "__publisher__" => "Nonsense", :id => Author.all.last.attribute_get(:id) }
      MerbMonkey.update_all(@controller).should == { :error => "No Publisher was found with name: Nonsense" }
      @controller.params.delete(:filter)      
    end

  end
  
  describe "delete" do

    it "should raise an unauthorized error if the model isn't authorized_for_delete" do
      Author.authorized_for_delete = false
      @controller.params[:model] = "Author"
      lambda { MerbMonkey.delete(@controller) }.should raise_error(MerbMonkey::Exceptions::Unauthorized)
      Author.authorized_for_delete = true
    end
    
    it "should delete an instance and return true if succesful" do
      sz = Author.all.size
      @controller.params[:_id] = sz + 1
      MerbMonkey.delete(@controller).should == true
      sz.should > Author.all.size
    end

  end
  
  describe "delete_all" do

    it "should raise an unauthorized error if the model isn't authorized_for_delete" do
      Author.authorized_for_delete = false
      @controller.params[:model] = "Author"
      lambda { MerbMonkey.delete_all(@controller) }.should raise_error(MerbMonkey::Exceptions::Unauthorized)
      Author.authorized_for_delete = true
    end

    it "should delete all instances that match the :obj params and return true" do
      Author.create(:name => "John Grisham")
      Author.create(:name => "John Updike")
      johns = Author.all(:name.like => "john%")
      johns.should_not be_empty
      @controller.params[:obj] = { "name" => "john" }
      MerbMonkey.delete_all(@controller).should == true
      Author.all(:name.like => "john%").should be_empty
    end

  end
  
  describe "upload" do

    before(:each) do
      books = Book.all.map { |a| a.attributes }
      @original_size = books.size
      books << Book.new(:title => "The Sum of All Fears", :author_id => 1).attributes
      books.first[:title] = "Rising Sun"
      @file = File.open(ExcelLoader::array_to_file(books, books.first.keys, Merb.root + "/tmp/Book.xls"), "r")
      @controller.params[:file] = { "tempfile" => @file, "filename" => "books.xls" }
      @controller.params[:model] = "Book"
    end

    it "should raise an unauthorized error if the model isn't authorized_for_create" do
      Book.authorized_for_create = false
      lambda { MerbMonkey.upload(@controller) }.should raise_error(MerbMonkey::Exceptions::Unauthorized)
      Book.authorized_for_create = true
    end
    
    it "should raise an unauthorized error if the model isn't authorized_for_update" do
      Book.authorized_for_update = false
      lambda { MerbMonkey.upload(@controller) }.should raise_error(MerbMonkey::Exceptions::Unauthorized)
      Book.authorized_for_update = true
    end
    
    it "should update the db with any changes to the data" do
      Book.first.title.should == "The Hunt for Red October"
      MerbMonkey.upload(@controller)
      Book.first.title.should == "Rising Sun"      
    end
    
    it "should add any new instances to the db" do
      MerbMonkey.upload(@controller)
      books = Book.all
      books.size.should == @original_size + 1
      books.last.title.should == "The Sum of All Fears"
    end

    it "should send an email saying there were no errors, if there were no errors" do
      Merb::Mailer.deliveries.last.subject.first.should match(/There_were_no_errors_in_your_upload/)
      Merb::Mailer.deliveries.last.multipart?.should == false
    end

    it "should send an email with an error message and attachment if there are errors" do
      book = Book.new(:title => "Carrier", :author_id => 1)
      book.__author__ = "Stephen King"
      book = book.attributes
      file = File.open(ExcelLoader::array_to_file([book], book.keys, Merb.root + "/tmp/Book.xls"), "r")
      @controller.params[:file] = { "tempfile" => file, "filename" => "books.xls" }
      @controller.params[:model] = "Book"
      MerbMonkey.upload(@controller)
      Merb::Mailer.deliveries.last.subject.first.should match(/here_were_errors_in_the_file_you_uploaded/)
      Merb::Mailer.deliveries.last.multipart?.should == true
    end

    it "should send the email to the address specified by the MerbMonkey.to_email method" do
      MerbMonkey[:to_email] = "homer@simpson.com"
      MerbMonkey.upload(@controller)
      Merb::Mailer.deliveries.last.to.first.should == "homer@simpson.com"
    end

    # This lets you specify the current user as the recipient
    it "should work when the MerbMonkey[:to_email] is a lambda" do
      class Kontroller; def user; "marge@simpson.com"; end; end
      MerbMonkey[:to_email] = lambda { |controller| controller.user }
      MerbMonkey.upload(@controller)
      Merb::Mailer.deliveries.last.to.first.should == "marge@simpson.com"
    end

  end
  
  describe "excel" do
    
    before(:each) do
      #books = Book.all.map { |a| a.attributes }
      #@original_size = books.size
      #books << Book.new(:title => "The Sum of All Fears", :author_id => 1).attributes
      #books.first[:title] = "Rising Sun"
      #@file = File.open(ExcelLoader::array_to_file(books, books.first.keys, Merb.root + "/tmp/Book.xls"), "r")
      #@controller.params[:file] = { "tempfile" => @file, "filename" => "books.xls" }
      @controller.params[:model] = "Author"
      @controller.params[:obj] = { "name" => "bill" }
    end
    
    it "should raise an unauthorized error if the model isn't authorized_for_read" do
      Author.authorized_for_read = false
      lambda { MerbMonkey.excel(@controller) }.should raise_error(MerbMonkey::Exceptions::Unauthorized)
      Author.authorized_for_read = true
    end
    
    it "should email the results if there are more than 200 model instances" do
      201.times { Author.create(:name => "Bill") }
      MerbMonkey.excel(@controller)
      Merb::Mailer.deliveries.last.subject.first.should match(/Download/)
      Merb::Mailer.deliveries.last.multipart?.should == true
    end
    
    it "should send the file immediately if there are fewer than 200 instance" do
      class Kontroller; def send_file(val); :worked; end; end
      Author.all(:name => "Bill").destroy!
      @controller.params[:obj] = { "name" => "tom" }
      MerbMonkey.excel(@controller).should == :worked
    end
    
  end
  
  describe "result_hash" do

    before(:all) do
      @book = Book.first
    end

    it "should return a hash with one key, an :error key" do
      h = MerbMonkey.send(:result_hash, @book)
      h.class.should == Hash
      h.keys.should == [:error]
    end
    
    it "should set the value to an empty string if there aren't any errors" do
      @book.save
      h = MerbMonkey.send(:result_hash, @book)
      h.should == { :error => "" }
    end
    
    it "should set the value to a string describing the validation errors if there are any" do
      class Point
        include DataMapper::Resource
        property :id, Serial
        property :lat, Integer, :required => true
        property :long, Integer, :required => true
      end
      Point.auto_migrate!
      @point = Point.new
      @point.save
      h = MerbMonkey.send(:result_hash, @point)
      h.should == { :error => "Lat must not be blank and Long must not be blank" }
    end

  end
  
  describe "monkey method" do
    
    before(:all) do
      class Journalist
        include DataMapper::Resource
        property :id, Serial
        property :name, String
        monkey
      end 
    end
    
    it "should add models to MerbMonkey.models hash" do
      MerbMonkey.models.keys.should include("Journalist")
    end
    
    it "should not pass a block if there isn't one" do
      MerbMonkey.models["Journalist"][:block].should == nil
    end

    it "should pass the block if there is one" do
      Journalist.monkey { |c| p c}
      MerbMonkey.models["Journalist"][:block].class.should == Proc
    end
    
  end
  
  describe "monkey_callback" do
  
    before(:all) do
      class Critic
        include DataMapper::Resource
        property :id, Serial
        property :name, String
        property :nickname, String
        belongs_to :publisher
      end
      @c = Critic.new
    end

    it "should create the instance method identified_as on the model" do
      @c.should_not respond_to(:identified_as)
      Critic.monkey_callback(nil)
      @c.should respond_to(:identified_as)
    end

    it "should modify the errors method on the instance" do
      @c.__publisher__ = "Nonsense"
      @c.errors[:publisher_id].should == ["No Publisher was found with name: Nonsense"]
    end
    
    it "should call init_relationship_defaults" do
      Critic.should_receive(:init_relationship_defaults)
      Critic.monkey_callback(nil)
    end
  
    it "should call the passed block" do
      l = lambda {}
      l.should_receive(:call)
      Critic.monkey_callback(l)
    end
    
    it "should pass the model and its properties to the block as parameters" do
      l = lambda {}
      l.should_receive(:call).with(Critic, Critic.properties)
      Critic.monkey_callback(l)      
    end

  end
  
  describe "MerbMonkey.enrich(params)" do
    
    it "should remove hash pairs who have an empty string as the value" do
      MerbMonkey.enrich("name" => nil).should == {}
      MerbMonkey.enrich("name" => "").should == {}
    end
    
    it "should ensure case insensitivity" do
      MerbMonkey.enrich("name" => "tom clancy").should == { :name.like => "tom clancy%" }
    end
    
    it "should add a wildcard to the end of the search string" do
      MerbMonkey.enrich("name" => "tom clancy").should == { :name.like => "tom clancy%" }
    end
    
    it "should add a like condition and wildcard to association finders" do
      MerbMonkey.enrich("author.name" => "tom").should == { "author.name.like" => "tom%" }
    end
    
    it "should not convert numbers into strings" do
      MerbMonkey.enrich("royalty" => 2).should == { "royalty" => 2 }
      MerbMonkey.enrich("royalty" => 2.5).should == { "royalty" => 2.5 }
    end
    
    it "should not conver strings that look like numbers to numbers" do
      MerbMonkey.enrich("royalty" => "2").should == { "royalty" => "2" }
      MerbMonkey.enrich("royalty" => "2.5").should == { "royalty" => "2.5" }
    end
    
    it "should know > means gt" do
      MerbMonkey.enrich("royalty" => "> 100").should == { :royalty.gt => "100" }
    end

    it "should know < means lt" do
      MerbMonkey.enrich("royalty" => "< 100").should == { :royalty.lt => "100" }
    end

    it "should know > means gte" do
      MerbMonkey.enrich("royalty" => ">= 100").should == { :royalty.gte => "100" }
    end

    it "should know < means lte" do
      MerbMonkey.enrich("royalty" => "<= 100").should == { :royalty.lte => "100" }
    end

    it "should know not means not" do
      MerbMonkey.enrich("name" => "not tom").should == { :name.not => "tom" }
    end
 
    it "should set boolean strings to actual booleans" do
      MerbMonkey.enrich("alive" => "true").should == { "alive" => true }
      MerbMonkey.enrich("alive" => "True").should == { "alive" => true }
      MerbMonkey.enrich("alive" => "false").should == { "alive" => false }
    end
    
    it "should not add a wildcard to the end of dates" do
      MerbMonkey.enrich("published" => "2009-01-01").should == { "published" => "2009-01-01" }
    end
          
  end
  
  describe "Authorizations" do

    describe "MerbMonkey defaults" do

      it "should have getter and setter methods for authorized_for_create" do
        MerbMonkey.should respond_to(:authorized_for_create)
        MerbMonkey.should respond_to(:authorized_for_create=)
      end

      it "should have getter and setter methods for authorized_for_read" do
        MerbMonkey.should respond_to(:authorized_for_read)
        MerbMonkey.should respond_to(:authorized_for_read=)
      end

      it "should have getter and setter methods for authorized_for_update" do
        MerbMonkey.should respond_to(:authorized_for_update)
        MerbMonkey.should respond_to(:authorized_for_update=)
      end

      it "should have getter and setter methods for authorized_for_delete" do
        MerbMonkey.should respond_to(:authorized_for_delete)
        MerbMonkey.should respond_to(:authorized_for_delete=)
      end
  
    end
  
    describe "check" do

      it "should return true by default" do
        MerbMonkey.check(nil).should == true
      end
      
      describe "when a lambda or proc is passed" do

        it "should call :call if first variable responds to :call" do
          l = lambda { true }
          l.should_receive(:call)
          MerbMonkey.check(l)
        end

        it "should pass the second variable if it exists" do
          l = lambda { true }
          h = {}
          l.should_receive(:call).with(h)
          MerbMonkey.check(l, h)
        end
        
        it "should return true if the result is true or exists" do
          MerbMonkey.check(lambda { |c| true }).should == true
        end
        
        it "should raise an unauthorized error if it returns false" do
          MerbMonkey.check(lambda { false }).should == false
        end
        
        it "should return false if there is an error" do
          MerbMonkey.check(lambda { raise StandardError }).should == false
        end
        
      end
      
      it "should return true if the result exists" do
        MerbMonkey.check(true).should == true
      end
      
      it "should return false if the parameter is false" do
        MerbMonkey.check(false).should == false
      end

    end
    
    describe "class-level authorization" do

      before(:all) do
        MerbMonkey.authorized_for_create = true
        MerbMonkey.authorized_for_read = true
        MerbMonkey.authorized_for_update = true
        MerbMonkey.authorized_for_delete = true
      end
      
      describe "setting authorization to a lambda" do

        it "should allow you to set an authorization to a proc or lambda" do
          lambda { Book.authorized_for_create = lambda { |controller| true } }.should_not raise_error
          lambda { Book.authorized_for_read = lambda { |controller| true } }.should_not raise_error
          lambda { Book.authorized_for_update = lambda { |controller| true } }.should_not raise_error
          lambda { Book.authorized_for_delete = lambda { |controller| true } }.should_not raise_error
        end

        it "should call the lambda in the getter method" do
          Book.authorized_for_create.should == true
          Book.authorized_for_read.should == true
          Book.authorized_for_update.should == true
          Book.authorized_for_delete.should == true
        end

      end
      
      it "should default the getter method for authorized_for_create to true" do
        Book.authorized_for_create.should == true
      end

      it "should default the getter method for authorized_for_read to true" do
        Book.authorized_for_read.should == true
      end

      it "should default the getter method for authorized_for_update to true" do
        Book.authorized_for_update.should == true
      end

      it "should default the getter method for authorized_for_delete to true" do
        Book.authorized_for_delete.should == true
      end

      it "should default to the MerbMonkey authorizations" do
        Book.authorized_for_read = nil
        MerbMonkey.authorized_for_read = false
        Book.authorized_for_read.should == false
      end
      
      it "should allow one to set model-level authorizations" do
        MerbMonkey.authorized_for_create = false
        MerbMonkey.authorized_for_read = false
        MerbMonkey.authorized_for_update = false
        MerbMonkey.authorized_for_delete = true
        
        Book.authorized_for_create = true
        Book.authorized_for_create.should == true
        
        Book.authorized_for_read = lambda { |c| c }
        Book.authorized_for_read(true).should == true

        Book.authorized_for_update = lambda { |c| true }
        Book.authorized_for_update.should == true

        Book.authorized_for_delete = false
        Book.authorized_for_delete.should == false
      end


    end
    


  end
  
  describe "Initialization" do

    before(:all) do
      class Distributor
        include DataMapper::Resource
        property :id, Serial
        property :name, String
        property :nickname, String
        belongs_to :author
      end
    end
    
    describe "at the model level" do
    
      describe "setting authorizations" do

        after(:all) do
          Distributor.authorized_for_create = true
          Distributor.authorized_for_read = true
          Distributor.authorized_for_update = true
          Distributor.authorized_for_delete = true
        end

        it "should allow you to specify authorization on create" do
          Distributor.authorized_for_create(nil).should == true
          Distributor.monkey_callback(lambda { |klass, properties| klass.authorized_for_create = false })
          Distributor.authorized_for_create(nil).should == false
        end

        it "should allow you to specify authorization on read" do
          Distributor.authorized_for_read(nil).should == true
          Distributor.monkey_callback(lambda { |klass, properties| klass.authorized_for_read = false })
          Distributor.authorized_for_read(nil).should == false
        end

        it "should allow you to specify authorization on update" do
          Distributor.authorized_for_update(nil).should == true
          Distributor.monkey_callback(lambda { |klass, properties| klass.authorized_for_update = false })
          Distributor.authorized_for_update(nil).should == false
        end

        it "should allow you to specify authorization on delete" do
          Distributor.authorized_for_delete(nil).should == true
          Distributor.monkey_callback(lambda { |klass, properties| klass.authorized_for_delete = false })
          Distributor.authorized_for_delete(nil).should == false
        end
      
      end

      it "should allow you to specify a different order" do
        l = lambda { |klass, properties| klass.order = [:id, :nickname, :author_id] }
        Distributor.monkey_callback(l)
        Distributor.order.should == [:id, :nickname, :author_id]
      end

      it "should allow you to specify a different label_singular" do
        l = lambda { |klass, properties| klass.label_singular = "Distribution Center" }
        Distributor.monkey_callback(l)
        Distributor.label_singular.should == "Distribution Center"
      end

      it "should allow you to specify a different label_plural" do
        l = lambda { |klass, properties| klass.label_plural = "Distribution Centers" }
        Distributor.monkey_callback(l)
        Distributor.label_plural.should == "Distribution Centers"
      end
    
      it "should allow you to specify a different identified_by field" do
        l = lambda { |klass, properties| klass.identified_by = :nickname }
        Distributor.monkey_callback(l)
        Distributor.identified_by.should == :nickname
      end

    end
   
    describe "at the property level" do

      it "should allow you to hide the property" do
        l = lambda { |klass, properties| properties[:name].hide = true }
        Distributor.monkey_callback(l)
        Distributor.properties[:name].hide.should == true
      end

      it "should allow you to hide the property in the index action" do
        l = lambda { |klass, properties| properties[:name].hide_in_index = true }
        Distributor.monkey_callback(l)
        Distributor.properties[:name].hide_in_index.should == true
      end

      it "should allow you to make the property readonly" do
        l = lambda { |klass, properties| properties[:name].readonly = true }
        Distributor.monkey_callback(l)
        Distributor.properties[:name].readonly.should == true
      end

      it "should allow you to set the header of the property" do
        l = lambda { |klass, properties| properties[:name].header = "Formal Name" }
        Distributor.monkey_callback(l)
        Distributor.properties[:name].header.should == "Formal Name"
      end

      it "should allow you to set the getter method of the property" do
        l = lambda { |klass, properties| properties[:author_id].getter = :author_name }
        Distributor.monkey_callback(l)
        Distributor.properties[:author_id].getter.should == :author_name
      end
      
      it "should allow you to set the setter method of the property" do
        l = lambda { |klass, properties| properties[:author_id].setter = :author_name }
        Distributor.monkey_callback(l)
        Distributor.properties[:author_id].setter.should == :author_name
      end

      it "should allow you to set the finder method of the property" do
        l = lambda { |klass, properties| properties[:author_id].finder = :writer }
        Distributor.monkey_callback(l)
        Distributor.properties[:author_id].finder.should == :writer
      end

    end
    
  end

  describe "init_for_controller" do
    
    it "should return a hash" do
      MerbMonkey.init_for_controller(@controller).class.should == Hash
    end
    
    describe "when the parameter is nil" do
      
      it "should return a hash of all the models in MerbMonkey" do
        h = MerbMonkey.init_for_controller(@controller)
        h.keys.size.should == MerbMonkey.models.keys.size
      end

    end
    
    describe "when the parameter has one model name" do

      it "should only return the hash for that model" do
        @controller.params[:model] = "Author"
        h = MerbMonkey.init_for_controller(@controller)
        h.keys.size.should == 1
      end
      
    end
    
    describe "when the parameter has more than one model name" do
      
      it "should return the hashes for those models" do
        @controller.params[:models] = "Author, Book"
        h = MerbMonkey.init_for_controller(@controller)
        h.keys.sort.should == %w{Author Book}
      end
      
    end

    it "should return the hash of init_for_controller called on each model" do
      h = MerbMonkey.init_for_controller(@controller)
      h.keys.sort[0].should == "Author"
      h["Author"].should == Author.init_for_controller(@controller)
    end

    it "should not include a model whose authorized_for_read is false" do
      Author.authorized_for_read = lambda { false }
      h = MerbMonkey.init_for_controller(@controller)
      h.keys.should_not include("Author")
      Author.authorized_for_read = true
    end

  end
end