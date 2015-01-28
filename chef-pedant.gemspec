Gem::Specification.new do |s|
  s.name          = 'chef-pedant'
  s.version       = '1.0.40'
  s.date          = '2014-01-25'
  s.summary       = "Chef API Testing Framework"
  s.authors       = ["Chef Software Engineering"]
  s.email         = 'dev@chef.io'
  s.require_paths = ['lib', 'spec']
  s.files         = Dir['lib/**/*'] + Dir['spec/**/*'] + Dir['bin/*'] + Dir['fixtures/**/*']
  s.homepage      = 'http://opscode.com'

  s.bindir        = 'bin'
  s.executables   = ['chef-pedant']

  s.add_dependency('rspec', '~> 3.1')
  s.add_dependency('activesupport', '~> 3.2.8') # For active_support/concern
  s.add_dependency('mixlib-authentication', '~> 1.3.0')
  s.add_dependency('mixlib-config', '~> 2.0')
  s.add_dependency('mixlib-shellout', '>= 1.1')
  s.add_dependency('rest-client', '>= 1.6.7')
  s.add_dependency('rspec_junit_formatter', '~> 0.2.0')
  s.add_dependency('net-http-spy', '~> 0.2.1')
  s.add_dependency('erubis', '~> 2.7.0')
  s.add_dependency('rspec-rerun', '= 0.1.1')
  # RSpec ReRun needs this to work.
  s.add_dependency('rspec-legacy_formatters', '~> 1.0')
end
