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

require 'mixlib/shellout'

module Pedant
  module RSpec
    module KnifeUtil
      extend Pedant::Concern

      included do
        subject { knife_run }
        let(:knife_run) { run command }
        let(:command)   { fail 'Define let(:command) in the spec' }

        # Our test repository for all knife commands.  Note that this is
        # relative to the top-level opscode-pedant directory.
        let(:repository) { Pedant::Utility.fixture_path "test_repository" }

        # The knife config file that everyone uses.  It is relative to
        # +repository+ (see above).
        #
        # TODO: In the future, have a knife config for each of multiple users
        let(:knife_config) { knife_config_for_admin_user }
        let(:knife_config_for_normal_user) { knife_user.knife_rb_path}
        let(:knife_config_for_admin_user)  { knife_admin.knife_rb_path }

        # Convenience method for creating a Mixlib::ShellOut representation
        # of a knife command in our test repository
        def shell_out(command_line)
          Mixlib::ShellOut.new(command_line, {'cwd' => repository})
        end

        # Convenience method for actually running a knife command in our
        # testing repository.  Returns the Mixlib::Shellout object ready for
        # inspection.
        def run(command_line)
          shell_out(command_line).tap(&:run_command)
        end

        def run_debug(command_line)
          shell_out(command_line.tap(&watch)).tap { |x| puts "status: #{x.status} #{x.stdout} #{x.stderr}" }
        end

        def knife(knife_command)
          run "knife #{knife_command}"
        end

        def knife_debug(knife_command)
          debug_run "knife #{knife_command}"
        end

      end # included

      module DataBag
        extend Pedant::Concern

        included do
          let(:bag_name) { "pedant_#{rand(1000000)}" }
          let(:assume_data_bag_item_file!) do
            File.open(data_bag_item_file_path, 'w') do |f|
              f.write(item_file_content)
            end
          end

          let(:data_bag_item_file_path) { "#{data_bag_dir}/#{item_name}.json" }
          let(:data_bag_dir) { "#{repository}/data_bags" }

          let(:available_characters) { [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten + [ ' ', '_', '|', '/' ] }

          let(:max_keys) { rand(7) + 3 }
          let(:item_name) { "item_#{rand(100000)}" }
          let(:with_random_key_and_value) { ->(h, i) { h.with(SecureRandom.uuid, SecureRandom.base64(rand(50) + 100)) } }
          let(:item) { (1..max_keys).to_a.inject({}, &with_random_key_and_value) }

          let(:item_file_content) { ::JSON.generate(item.with(:id, item_name)) }

        end
      end
    end # KnifeUtil
  end # RSpec
end # Pedant
