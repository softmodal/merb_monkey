require File.join( File.dirname(__FILE__), '..', "spec_helper" )
 
describe "to_array_of_hashes" do

  before(:all) do
    Book.properties[:published].hide = true
    Book.order = [:title, :author_id]
    @books = Book.all.to_array_of_hashes
  end
  
  after(:all) do
    Book.properties[:published].hide = false
  end
  
  it "should return an array of hashes" do
    @books.class.should == Array
    @books.first.class.should == Hash
  end
  
  it "should not include properties whose hide method is false in the hashes" do
    @books.first.keys.should_not include(:published)
  end
  
  it "should only include properties that are in the order method of the model" do
    @books.first.keys.should include("__author__")
    @books.first.keys.should include("title")
  end
  
  it "should ensure the serial field is present" do
    @books.first.keys.should include("id")
  end
  
end