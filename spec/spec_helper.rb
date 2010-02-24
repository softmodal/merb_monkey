require 'rubygems'
require 'merb-core'
require 'merb-slices'
require 'spec'

# Add merb_monkey.rb to the search path
Merb::Plugins.config[:merb_slices][:auto_register] = true
Merb::Plugins.config[:merb_slices][:search_path]   = File.join(File.dirname(__FILE__), '..', 'lib')
Merb::Plugins.config[:merb_slices][:search_path]   = File.join(File.dirname(__FILE__), '..', 'lib', 'merb_monkey.rb')

# Require merb_monkey.rb explicitly so any dependencies are loaded
require Merb::Plugins.config[:merb_slices][:search_path]

# Using Merb.root below makes sure that the correct root is set for
# - testing standalone, without being installed as a gem and no host application
# - testing from within the host application; its root will be used
Merb.start_environment(
  :testing => true, 
  :adapter => 'runner', 
  :environment => ENV['MERB_ENV'] || 'test',
  :session_store => 'memory'
)

module Merb
  module Test
    module SliceHelper
      
      # The absolute path to the current slice
      def current_slice_root
        @current_slice_root ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))
      end
      
      # Whether the specs are being run from a host application or standalone
      def standalone?
        Merb.root == ::MerbMonkey.root
      end
      
    end
  end
end

class Merb::Mailer
  self.delivery_method = :test_send
end
#Mail.defaults do
#  delivery_method :test
#end


Spec::Runner.configure do |config|
  config.include(Merb::Test::ViewHelper)
  config.include(Merb::Test::RouteHelper)
  config.include(Merb::Test::ControllerHelper)
  config.include(Merb::Test::SliceHelper)
end

# You can add your own helpers here
#
Merb::Test.add_helpers do
  def mount_slice
    Merb::Router.prepare { add_slice(:MerbMonkey, "merb_monkey") } if standalone?
  end

  def dismount_slice
    Merb::Router.reset! if standalone?
  end
end

class Merb::Rack::StreamWrapper
  
  def parse_json
    JSON.parse(self.to_s)
  end
  
end
