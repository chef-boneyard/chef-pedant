# Copyright: Copyright (c) 2012 Opscode, Inc.
# License: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'pp' # Debugging

require 'rspec'
require 'rspec-shared'

require 'pedant/concern'
require 'pedant/json'
require 'pedant/requestor'
require 'pedant/request'
require 'pedant/platform'
require 'pedant/config'
require 'pedant/utility'
require 'pedant/sandbox'
require 'pedant/chef_utility'
require 'pedant/command_line'
require 'pedant/gem'
require 'pedant/knife'
require 'pedant/ui'

require 'pedant/rspec/matchers'
require 'pedant/rspec/common'

module Pedant
  def self.config
    Config
  end

  def self.setup(argv=[], option_sets=["core_options", "api_options"])
    config.from_argv(argv, option_sets)
    puts "Configuring logging..."
    configure_logging
    puts "Creating platform..."
    create_platform
    configure_rspec
  end

  # Enable detailed HTTP traffic logging for debugging purposes
  def self.configure_logging
    if config.log_file
      require 'net-http-spy'
      Net::HTTP.http_logger_options = {
        :trace =>true,
        :verbose => true,
        :body => true
      }
      Net::HTTP.http_logger = Logger.new(config.log_file)
    end
  end

  def self.create_platform
    platform_class = config.platform_class
    raise "Must specify an implementation class of Pedant::Platform!  Use the `platform_class` key in your Pedant config file" unless platform_class

    config.pedant_platform = platform_class.new(config.chef_server,
                                                config.superuser_key,
                                                config.superuser_name)
    end

  def self.configure_rspec
    ::RSpec.configure do |c|
      c.treat_symbols_as_metadata_keys_with_true_values = true

      # If you just want to run one (or a few) tests in development,
      # add :focus metadata
      c.filter_run :focus => true

      if Pedant.config.only_internal
        c.filter_run :cleanup
      else
        c.filter_run_excluding :cleanup => true unless Pedant.config.include_internal
      end

      c.run_all_when_everything_filtered = true

      # This needs to be included everywhere
      c.include Pedant::RSpec::Common

      platform = Pedant::Config.pedant_platform

      if platform.respond_to?(:configure_rspec)
        puts "setting up rspec config for #{platform}"
        platform.configure_rspec
      end

      c.before(:suite) do
        platform.setup
      end

      c.after(:suite) do
        platform.cleanup
      end

    end
  end
end
