# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{merb_monkey}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Jon Sarley}]
  s.date = %q{2011-07-06}
  s.description = %q{MerbMonkey is a jQuery-powered admin slice for DataMapper}
  s.email = %q{jsarley@softmodal.com}
  s.extra_rdoc_files = [%q{README}, %q{LICENSE}, %q{TODO}]
  s.files = [%q{LICENSE}, %q{README}, %q{Rakefile}, %q{TODO}, %q{lib/constants.rb}, %q{lib/merb_monkey}, %q{lib/merb_monkey/merbtasks.rb}, %q{lib/merb_monkey/slicetasks.rb}, %q{lib/merb_monkey/spectasks.rb}, %q{lib/merb_monkey.rb}, %q{lib/monkey_collection.rb}, %q{lib/monkey_model.rb}, %q{lib/monkey_property.rb}, %q{lib/uploadable.rb}, %q{spec/lib}, %q{spec/lib/monkey_collection_spec.rb}, %q{spec/lib/uploadable_spec.rb}, %q{spec/merb_monkey_spec.rb}, %q{spec/requests}, %q{spec/requests/main_spec.rb}, %q{spec/spec_helper.rb}, %q{app/controllers}, %q{app/controllers/application.rb}, %q{app/controllers/main.rb}, %q{app/helpers}, %q{app/helpers/application_helper.rb}, %q{app/views}, %q{app/views/layout}, %q{app/views/layout/merb_monkey.html.erb}, %q{app/views/main}, %q{app/views/main/index.html.erb}, %q{public/javascripts}, %q{public/javascripts/ajaxupload.js}, %q{public/javascripts/jquery.hotkeys-0.7.9.js}, %q{public/javascripts/jquery.hotkeys-0.7.9.min.js}, %q{public/javascripts/jquery.js}, %q{public/javascripts/monkey.js}, %q{public/stylesheets}, %q{public/stylesheets/master.css}, %q{stubs/app}, %q{stubs/app/controllers}, %q{stubs/app/controllers/application.rb}, %q{stubs/app/controllers/main.rb}]
  s.homepage = %q{http://softmodal.com/}
  s.require_paths = [%q{lib}]
  s.rubyforge_project = %q{merb}
  s.rubygems_version = %q{1.8.5}
  s.summary = %q{MerbMonkey is a jQuery-powered admin slice for DataMapper}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
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
