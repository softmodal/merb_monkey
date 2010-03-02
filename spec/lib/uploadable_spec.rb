require File.join( File.dirname(__FILE__), '..', "spec_helper" )
 
describe Uploadable do
  EXTENSIONS = %w{.csv .psv .xls}
  before(:all) do
    class Book
      include DataMapper::Resource
      extend Uploadable
      property :id, Serial
      property :title, String
      property :published, Date
      property :notes, Text
      property :royalty, Integer
      belongs_to :author
    end

    class Author
      include DataMapper::Resource  
      extend Uploadable
      property :id, Serial
      property :name, String
      property :alive, Boolean, :default => true
      has n, :books
      belongs_to :publisher, :required => false
    end

    class Publisher
      include DataMapper::Resource
      extend Uploadable
      property :id, Serial
      property :name, String
    end
    
    DataMapper.auto_migrate!
    Publisher.create(:name => "Random House")
    Author.create(:name => "Tom Clancy", :publisher_id => 1)
    Author.create(:name => "Patrick O'Brian", :publisher_id => 1)
    Book.create(:title => "The Hunt for Red October", :royalty => 100000, :author_id => 1)
    Book.create(:title => "Master and Commander", :royalty => 50000, :author_id => 2)

    @data = [
      {:title => "Rising Sun", :royalty => 1000000, :__author__ => "Tom Clancy"},
      {:title => "Post Captain", :royalty => 75000, :__author__ => "Patrick O'Brian"}
    ]
      
    @tmp_path = Merb.root + "/tmp/books"
    doc = [@data[0].keys.map { |k| k.to_s }.join(",")] +
    (@data.map do |row|
      row.map { |k,v| v.to_s }.join(",")
    end)
    doc = doc.join("\n")
    File.open(@tmp_path + ".csv", 'w') {|f| f.write(doc) }
    File.open(@tmp_path + ".psv", 'w') {|f| f.write(doc.gsub(",", "|")) }
    ExcelLoader.array_to_file(@data, nil, @tmp_path + ".xls")
  end
  
  after(:all) do
    EXTENSIONS.each { |extension| File.delete(@tmp_path + extension) }
  end
  
  describe "::file_to_array" do
    EXTENSIONS.each do |ext|
      it "should read #{ext} files" do
        lambda { Book::file_to_array(@tmp_path + ext) }.should_not raise_error
      end
      it "should return an array of hashes for #{ext} files" do
        arr = Book::file_to_array(@tmp_path + ext)
        arr.class.should == Array
        arr[0].class.should == Hash
      end
    end
    it "should raise an error for any other file type" do
      lambda {
        Book::file_to_array(@tmp_path + ".pdf")
      }.should raise_error(ArgumentError)
    end
  end
  describe "::cache_associations" do
    it "should accept a hash parameter of data"
    it "should return the parameter unaltered if associations_to_cache isn't set in the model"
    it "should raise an invalid format error if associations_to_cache doesn't return a hash"
    it "should use the keys of the hash as the column names to replace"
    it "should ignore incorrect parameters from associations_to_cache"
    it "should work with complex associations that have child keys"
    it "should replace association attributes to save database lookups"
    it "should use the parent model's name attribute"
    it "should use the parent model's nick_name attribute"
  end
  describe "::batch_insert" do
    before(:each) do
      Book.auto_migrate!
    end
    it "should add the hashes as records in the model table" do
      Book.all.size.should == 0
      Book.batch_insert(@data)
      Book.all.size.should == 2
    end
    it "should try to cache associations by default" do
      Book.batch_insert(@data)
      Book.should_receive(:cache_associations).with(@data).and_return(Book.cache_associations(@data))
    end
    it "should skip caching if the second parameter is false" do
      Book.batch_insert(@data, false)
      Book.should_not_receive(:cache_associations)
    end
    it "should call :save_without_before_filter if that method exists in the model" do
      class Book
        def save_without_before_filter
          # does nothing
        end
      end
      Book.batch_insert(@data)
      Book.all.size.should == 0
      class Book; undef :save_without_before_filter; end
    end
    it "should return an empty array if there are no errors" do
      Book.batch_insert(@data).should == []
    end
    
    describe "if there is an id parameter in the row then we're updating" do
      before(:each) do
        Book.auto_migrate!
        Book.create(:title => "The Hunt for Red October", :royalty => 100000, :author_id => 1)
      end
      it "should update the correct object from the database" do
        Book.batch_insert([:id => 1, :royalty => 75000])
        books = Book.all
        books.size.should == 1
        books.first.royalty.should == 75000
      end
      it "should append an error saying the object couldn't be found if there's no object with that id" do
        errs = Book.batch_insert([:id => 10001, :royalty => 50000])
        errs.first[:errors].should == "No book was found with this id"
      end
    end
    
    describe "if there are errors" do
      
      before(:all) do
        @data.push(:__author__ => "Stephen King", :title => "The Shining", :royalty => 95000)
        @arr = Book.batch_insert(@data)
      end
      
      it "should return an array of hashes" do
        @arr.size.should == 1
        @arr[0].class.should == Hash
      end
      
      it "the hashes should include the row data and the errors" do
        @arr[0][:title].should == "The Shining"
        @arr[0][:errors].should_not == nil
      end
      
    end
  end
  describe "::upload" do
    it "should take a path parameter as its first argument" do
      lambda { Book.upload(@tmp_path + ".psv") }.should_not raise_error
    end
    it "should take a cache parameter as its optional second argument" do
      lambda { Book.upload(@tmp_path + ".psv", false) }.should_not raise_error
    end
    it "should take a path name and insert its contents in the model's table" do
      EXTENSIONS.each do |ext|
        Book.auto_migrate!
        Book.upload(@tmp_path + ext, true)
        Book.all.size.should == 2
        Book.auto_migrate!
        Book.upload(@tmp_path + ext, false)
        Book.all.size.should == 2
        Book.auto_migrate!
      end
    end
  end
  describe "check_headers" do
    before(:all) do
      class Author
        include DataMapper::Resource
        extend Uploadable
        property :id, Serial
        property :name, String
      end
      @authors = [{:name => "Michael Dibdin"}, {:name => "Patrick O'Brian"}, {:name => "Michael Connelly"}]
    end
    it "should raise an error if the first item in data array has a header that the class doesn't respond_to" do
      @authors[0][:country] = "Irish"
      lambda {
        Author.check_headers(@authors)
      }.should raise_error(ArgumentError, "Author has no attribute: 'country'")
      @authors[0].delete(:country)
    end
    it "should raise an error if any item in the data array has a header that the class doesn't respond_to" do
      @authors[2][:city] = "Los Angeles"
      lambda {
        Author.check_headers(@authors)
      }.should raise_error(ArgumentError, "Author has no attribute: 'city'")
    end
    it "should raise one error that includes all of the headers don't match attributes" do
      @authors[1][:country] = "UK"
      lambda {
        Author.check_headers(@authors)
      }.should raise_error(ArgumentError, "Author has no attributes: 'country', 'city'")
    end
    it "should not raise an error if the headers match" do
      @authors[2].delete(:city)
      @authors[1].delete(:country)
      lambda {
        Author.check_headers(@authors)
      }.should_not raise_error
    end
  end
  
  describe "cache" do
    
    before(:all) do
      class Book
        def self.associations_to_cache
          { :__author__ => :author_id }
        end
      end
      @data = Book.cache([
        { "__author__" => "Tom Clancy", "royalty" => 75000, "title" => "Rising Sun" },
        { "__author__" => "Patrick O'Brian", "royalty" => 50000, "title" => "Post Captain" },
        { "__author__" => "Patrick O'Brian", "royalty" => 50000, "title" => "Post Captain" }
      ])
    end
    
    it "should replace the associations_to_cache keys with their values in the data" do
      @data.first.keys.should_not include("__author__")
      @data.first.keys.should include(:author_id)
    end
    
    it "should replace the values in the data with the appropriate ids" do
      @data.first[:author_id].should == 1
      @data.last[:author_id].should == 2
    end

  end
end