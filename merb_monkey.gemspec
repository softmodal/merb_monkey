# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{merb_monkey}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jon Sarley"]
  s.date = %q{2011-07-05}
  s.description = %q{MerbMonkey is a jQuery-powered admin slice for DataMapper}
  s.email = %q{jsarley@softmodal.com}
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/constants.rb", "lib/merb_monkey", "lib/merb_monkey/merbtasks.rb", "lib/merb_monkey/slicetasks.rb", "lib/merb_monkey/spectasks.rb", "lib/merb_monkey.rb", "lib/monkey_collection.rb", "lib/monkey_model.rb", "lib/monkey_property.rb", "lib/uploadable.rb", "spec/lib", "spec/lib/monkey_collection_spec.rb", "spec/lib/uploadable_spec.rb", "spec/merb_monkey_spec.rb", "spec/requests", "spec/requests/main_spec.rb", "spec/spec_helper.rb", "app/controllers", "app/controllers/application.rb", "app/controllers/main.rb", "app/helpers", "app/helpers/application_helper.rb", "app/views", "app/views/layout", "app/views/layout/merb_monkey.html.erb", "app/views/main", "app/views/main/index.html.erb", "public/javascripts", "public/javascripts/ajaxupload.js", "public/javascripts/jquery.hotkeys-0.7.9.js", "public/javascripts/jquery.hotkeys-0.7.9.min.js", "public/javascripts/jquery.js", "public/javascripts/monkey.js", "public/stylesheets", "public/stylesheets/master.css", "stubs/app", "stubs/app/controllers", "stubs/app/controllers/application.rb", "stubs/app/controllers/main.rb"]
  s.homepage = %q{http://softmodal.com/}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{merb}
  s.rubygems_version = %q{1.3.6}
  s.summary = %q{MerbMonkey is a jQuery-powered admin slice for DataMapper}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<merb-slices>, [">= 1.0.15"])
      s.add_runtime_dependency(%q<merb-assets>, [">= 0"])
      s.add_runtime_dependency(%q<dm-aggregates>, [">= 0"])
      s.add_runtime_dependency(%q<merb-mailer>, [">= 0"])
      s.add_runtime_dependency(%q<excel_loader>, [">= 0"])
    else
      s.add_dependency(%q<merb-slices>, [">= 1.0.15"])
      s.add_dependency(%q<merb-assets>, [">= 0"])
      s.add_dependency(%q<dm-aggregates>, [">= 0"])
      s.add_dependency(%q<merb-mailer>, [">= 0"])
      s.add_dependency(%q<excel_loader>, [">= 0"])
    end
  else
    s.add_dependency(%q<merb-slices>, [">= 1.0.15"])
    s.add_dependency(%q<merb-assets>, [">= 0"])
    s.add_dependency(%q<dm-aggregates>, [">= 0"])
    s.add_dependency(%q<merb-mailer>, [">= 0"])
    s.add_dependency(%q<excel_loader>, [">= 0"])
  end
end
