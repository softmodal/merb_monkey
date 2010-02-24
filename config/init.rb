#
# ==== Standalone MerbMonkey configuration
# 
# This configuration/environment file is only loaded by bin/slice, which can be 
# used during development of the slice. It has no effect on this slice being
# loaded in a host application. To run your slice in standalone mode, just
# run 'slice' from its directory. The 'slice' command is very similar to
# the 'merb' command, and takes all the same options, including -i to drop 
# into an irb session for example.
#
# The usual Merb configuration directives and init.rb setup methods apply,
# including use_orm and before_app_loads/after_app_loads.
#
# If you need need different configurations for different environments you can 
# even create the specific environment file in config/environments/ just like
# in a regular Merb application. 
#
# In fact, a slice is no different from a normal # Merb application - it only
# differs by the fact that seamlessly integrates into a so called 'host'
# application, which in turn can override or finetune the slice implementation
# code and views.
#

use_orm :datamapper
use_test :rspec
use_template_engine :erb

Merb::Config.use do |c|

  # Sets up a custom session id key which is used for the session persistence
  # cookie name.  If not specified, defaults to '_session_id'.
  # c[:session_id_key] = '_session_id'
  
  # The session_secret_key is only required for the cookie session store.
  c[:session_secret_key]  = 'cbcb656da7d4667e2ce4fd7b3eae4b08e248dd53'
  
  # There are various options here, by default Merb comes with 'cookie', 
  # 'memory', 'memcache' or 'container'.  
  # You can of course use your favorite ORM instead: 
  # 'datamapper', 'sequel' or 'activerecord'.
  c[:session_store] = 'cookie'
  
  # When running a slice standalone, you're usually developing it,
  # so enable template reloading by default.
  c[:reload_templates] = true
  
end

Merb::BootLoader.before_app_loads do
  Merb::Slices.config[:merb_monkey] = { 
    :read => lambda { |controller| true }
  }
  # Don't forget MerbMonkey == Merb::Slices::config[:merb_monkey] in this slice
  MerbMonkey[:from_email] = "Homer Simpson <homer@simpson.com>"
  MerbMonkey[:to_email] = lambda { "marge@simpson.com" }
end

Merb::BootLoader.after_app_loads do
  require 'dm-validations'
  DataMapper.setup(:default, 'sqlite3::memory:')

  class Book
    include DataMapper::Resource
    property :id, Serial
    property :title, String
    property :published, Date
    property :notes, Text
    property :royalty, Integer
    belongs_to :author#, :required => false

    monkey do |klass, props|
      klass.identified_by = :title
      #klass.order = [:id, :title, :author_id, :published, :royalty, :notes]
      props[:published].hide = true
    end

  end
  
  class Author
    include DataMapper::Resource  
    property :id, Serial
    property :name, String
    property :alive, Boolean, :default => true
    has n, :books
    belongs_to :publisher, :required => false
    monkey
  end
  
  class Publisher
    include DataMapper::Resource
    property :id, Serial
    property :name, String
    monkey
  end
  
  DataMapper.auto_migrate!
  Publisher.create(:name => "Random House")
  clancy = Author.create(:name => "Tom Clancy", :alive => true, :publisher_id => 1)
  obrien = Author.create(:name => "Patrick O'Brien", :alive => false)
  999.times do |i|
    Author.create(:name => rand * 100990)
  end
  clancy.books.create(:title => "The Hunt for Red October", :published => "1986-04-01", :royalty => 10000)
  obrien.books.create(:title => "Post Captain", :published => "1963-10-14", :royalty => 15000)
  obrien.books.create(:title => "The Ionian Mission", :published => "1973-02-14", :royalty => 25000)
  
  # Activate SSL Support
  dependency 'tlsmail'
  Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
  Merb::Mailer.config = {
    :host   => 'smtp.gmail.com',
    :port   => '587',
    :user   => '****@gmail.com',
    :pass   => '****',
    :auth   => :plain
  }
  
  module Merb
    class Mailer
      # Sends the mail using SMTP.
      def net_smtp
        Net::SMTP.start(config[:host], config[:port].to_i, config[:domain],
                        config[:user], config[:pass], config[:auth]) { |smtp|
          #smtp.send_message(@mail.to_s, extract_addresses(@mail.from.first), @mail.to.to_s.split(/[,;]/))
          smtp.send_message(@mail.to_s, extract_addresses(@mail.from.first), extract_addresses(@mail.to.to_s).split(/[,;]\s*/))
        }
      end

      # Pulls addresses out of a string
      # Example:
      #
      #   str = "Homer Simpson <homer@simpson.com>, Marge Simpson <marge@simpson.com>"
      #   extract_addresses(str) #=> "homer@simpson.com,marge@simpson.com"
      def extract_addresses(field)
        field.dup.gsub(/[^<,]*<([^<]*)>/, '\1,').gsub(/,$/, "").gsub(/,+/, ",")
      end
    end
  end
end