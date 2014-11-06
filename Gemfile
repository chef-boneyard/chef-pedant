source "https://rubygems.org"

gemspec
gem 'rspec', '~>2.14.0'
gem "rest-client", :git => "git://github.com/opscode/rest-client.git"

# If you want to load debugging tools into the bundle exec sandbox,
# # add these additional dependencies into Gemfile.local
eval(IO.read(__FILE__ + '.local'), binding) if File.exists?(__FILE__ + '.local')
