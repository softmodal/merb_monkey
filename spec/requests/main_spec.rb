require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

# Model data is specified in init.rb
describe  "/merb_monkey/" do
  
  before(:all) do
    mount_slice
  end
  
  describe "GET /" do
    
    before(:each) do
      @response = request("/merb_monkey/")
    end
    
    it "should be successful" do
      @response.status.should be_successful
    end
    
  end
  
  describe "/init" do
    
    before(:each) do
      @response = request("/merb_monkey/init")
    end
    
    it "should be successful" do
      @response.status.should be_successful
    end
    
    it "should return a JSON string" do
      @response.body.parse_json.class.should == Hash
    end
    
    describe "model param" do
      
      it "should specify which models to return" do
        json = request("/merb_monkey/init?model=Author").body.parse_json
        json.size.should == 1
        json["Author"].should_not be_nil
      end

      it "should also be called 'models'" do
        json = request("/merb_monkey/init?models=Author,Book").body.parse_json
        json.size.should == 2
        json["Author"].should_not be_nil
        json["Book"].should_not be_nil
      end

      it "should be case insensitive" do
        json = request("/merb_monkey/init?model=auTHor,book").body.parse_json
        json.size.should == 2
        json["Author"].should_not be_nil
        json["Book"].should_not be_nil
      end
      
      it "if empty, it should return all models specified in MerbMonkey.models" do
        json = @response.body.parse_json
        json.size.should == 3
        json["Author"].should_not be_nil
        json["Book"].should_not be_nil
        json["Publisher"].should_not be_nil
      end
      
    end
    
    describe "authorization" do

      before(:each) do
        Publisher.authorized_for_read = true
      end

      it "should not return a model if c[:read] is set to false" do
        Publisher.authorized_for_read = false
        request("/merb_monkey/init?model=Publisher").body.parse_json.should == {}
      end

      it "should not return a model if c[:read] is an object whose 'call' method evaluates to false" do
        Publisher.authorized_for_read = lambda { false }
        request("/merb_monkey/init?model=Publisher").body.parse_json.should == {}
        Publisher.authorized_for_read = Proc.new { false }
        request("/merb_monkey/init?model=Publisher").body.parse_json.should == {}      
      end

      it "should correctly set the model's :create attribute in the returned json" do
        Publisher.authorized_for_create = true
        request("/merb_monkey/init").body.parse_json["Publisher"]["authorized_for_create"].should == true
        Publisher.authorized_for_create = lambda { false }
        request("/merb_monkey/init?model=Publisher").body.parse_json["Publisher"]["authorized_for_create"].should == false
      end

      it "should correctly set the model's :update attribute in the returned json" do
        Publisher.authorized_for_update = true
        request("/merb_monkey/init").body.parse_json["Publisher"]["authorized_for_update"].should == true
        Publisher.authorized_for_update = lambda { false }
        request("/merb_monkey/init").body.parse_json["Publisher"]["authorized_for_update"].should == false
      end

      it "should correctly set the model's :delete attribute in the returned json" do
        Publisher.authorized_for_delete = true
        request("/merb_monkey/init").body.parse_json["Publisher"]["authorized_for_delete"].should == true
        Publisher.authorized_for_delete = lambda { false }
        request("/merb_monkey/init").body.parse_json["Publisher"]["authorized_for_delete"].should == false
      end

    end
    
  end

  describe "autocomplete" do

    it "should return a json object that includes the autocomplete array for each model passed" do
      json = request("/merb_monkey/autocomplete?model=Publisher").body.parse_json
      json["Publisher"].should == ["Random House"]
    end
    
    it "should return a json object that includes multiple arrays if more than one model is passed" do
      json = request("/merb_monkey/autocomplete?model=Publisher,%20Book").body.parse_json
      json["Publisher"].should == ["Random House"]
      json["Book"].should == ["Post Captain", "The Hunt for Red October", "The Ionian Mission"]
    end

  end
  
  describe "/list" do
    
    it "should return an unauthorized json error if the request is not authorized for :read on that model" do
      Book.authorized_for_read = false
      json = request("/merb_monkey/list?model=Book").body.parse_json
      json["error"].should == "You are not authorized for this action"
      Book.authorized_for_read = true
    end
    
    it "should return an empty string for count if params[:count] is false" do
      json = request("/merb_monkey/list?model=Book&obj[title]=blah&count=false").body.parse_json
      json["count"].should == ""
    end

    it "should return the count if params[:count] is any other value" do
      Book.stub(:count).and_return(5)
      json = request("/merb_monkey/list?model=Book&obj[title]=blah&count=true").body.parse_json
      json["count"].should == 5
    end
    
    it "should return the count if params[:count] is not present" do
      Book.stub(:count).and_return(5)
      json = request("/merb_monkey/list?model=Book&obj[title]=blah").body.parse_json
      json["count"].should == 5
    end    
    
    it "should return row data in the json string" do
      Author.create(:name => "Michael Dibdin")
      Book.create(:title => "Ratking", :author_id => 1)
      json = request("/merb_monkey/list?model=Book&obj[title]=post&limit=10&offset=0&count=false").body.parse_json
      rows = json["rows"]
      rows.size.should == 1
      rows.first["title"].should == "Post Captain"
    end
    
  end
  
  describe "/create" do
    
    it "should return an unauthorized json error if the request is not authorized_for_create on that model" do
      Book.authorized_for_create = lambda { false }
      json = request("/merb_monkey/create?model=Book").body.parse_json
      json["error"].should == "You are not authorized for this action"
    end
    
    it "should create an object with the parameters passed" do
      Book.authorized_for_create = true
      ct = Book.all.size
      json = request("/merb_monkey/create?model=Book&obj[title]=Ratking&obj[__author__]=Michael%20Dibdin").body.parse_json
      Book.all.size.should == ct + 1
      json["error"].should == ""
    end
    
    it "should not create any objects and return a json error if any validations fail" do
      ct = Book.all.size
      json = request("/merb_monkey/create?model=Book&obj[title]=Ratking&obj[__author__]=blah").body.parse_json
      Book.all.size.should == ct
      json["error"].should == "No Author was found with name: blah"
    end
    
  end
  
  describe "/update" do
    
    it "should return an unauthorized json error if the request is not authorized for :update on that model" do
      Book.authorized_for_update = false
      json = request("/merb_monkey/update?model=Book").body.parse_json
      json["error"].should == "You are not authorized for this action"
      Book.authorized_for_update = true
    end
    
    it "should update an object with the parameters passed" do
      json = request("/merb_monkey/update?model=Book&obj[title]=Ratking&obj[id]=1").body.parse_json
      b = Book.first
      b.title.should == "Ratking"
      json["error"].should == ""
      b.update(:title => "The Hunt for Red October")
    end
    
    it "should not update any objects and return a json error if any validations fail" do
      json = request("/merb_monkey/update?model=Book&obj[__author__]=blah&obj[id]=1").body.parse_json
      json["error"].should == "No Author was found with name: blah"
    end
    
  end
  
  describe "/update_all" do
    
    it "should return an unauthorized json error if the request is not authorized for :update on that model" do
      Book.authorized_for_update = false
      json = request("/merb_monkey/update_all?model=Book").body.parse_json
      json["error"].should == "You are not authorized for this action"
      Book.authorized_for_update = true
    end
    
    it "should update all objects that share the filter parameters with the field(s) changed in the obj parameters" do
      json = request("/merb_monkey/update_all?model=Book&filter[title]=the&obj[__author__]=Michael%20Dibdin&obj[id]=1").body.parse_json
      json["error"].should == ""      
      Book.first(:title => "The Ionian Mission").author.name.should == "Michael Dibdin"
      Book.first(:title => "The Hunt for Red October").author.name.should == "Michael Dibdin"
    end
    
    it "should not update any objects and return a json error if any validations fail" do
      json = request("/merb_monkey/update_all?model=Book&obj[__author__]=blah&obj[id]=1").body.parse_json
      json["error"].should == "No Author was found with name: blah"
    end
    
  end
  
  describe "/delete" do
    
    it "should return an unauthorized json error if the request is not authorized for :delete on that model" do
      Book.authorized_for_delete = lambda { |c| c.class == Hash }
      json = request("/merb_monkey/delete?model=Book").body.parse_json
      json["error"].should == "You are not authorized for this action"
      Book.authorized_for_delete = true
    end
    
    it "should delete an object" do
      ct = Book.all.size
      request("/merb_monkey/delete?model=Book&_id=1").body.to_s.should == "true"
      Book.all.size.should == ct - 1
    end
    
    it "should return a json error if any is raised" do
      json = request("/merb_monkey/delete?model=Book&_id=30").body.parse_json
      json["error"].should_not be_empty
    end
    
  end
  
  describe "/delete_all" do
    
    it "should return an unauthorized json error if the request is not authorized for :delete on that model" do
      Book.authorized_for_delete = false
      json = request("/merb_monkey/delete_all?model=Book").body.parse_json
      json["error"].should == "You are not authorized for this action"
      Book.authorized_for_delete = true
    end
    
    it "should delete all objects that share the obj parameters" do
      ct = Book.all.size
      request("/merb_monkey/delete_all?model=Book&obj[author.name]=Michael%20Dibdin").body.to_s.should == "true"
      Book.all.size.should == ct - 2
    end
        
  end

  describe "upload" do

    it "should return an unauthorized json error if the request is not authorized_for_create on that model" do
      Book.authorized_for_create = lambda { false }
      json = request("/merb_monkey/upload?model=Book").body.parse_json
      json["error"].should == "You are not authorized for this action"
      Book.authorized_for_create = true
    end

  end

  describe "helper methods" do

    before(:all) do
      class Obj
        def params
          { :model => "Author" }
        end
      end
      @instance = MerbMonkey::Main.new(Obj.new)
    end

    describe "model_name_and_class" do

      it "should return the model name and class of the model passed in the 'model' parameter" do
        model_name, model_class = @instance.send(:model_name_and_class)
        model_name.should == "Author"
        model_class.should == Author
      end

    end

    describe "json_error" do
      
      it "should return a json object with the error message" do
        json = @instance.send(:json_error, "There was an error")
        JSON.parse(json)["error"].should == "There was an error"
      end
      
    end

  end
  
end