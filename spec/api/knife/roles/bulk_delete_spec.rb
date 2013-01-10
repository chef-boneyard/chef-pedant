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

require 'pedant/rspec/knife_util'
require 'securerandom'

describe 'knife', knife: true, pending: !open_source? do
  context 'role' do
    context 'bulk delete REGEX' do
      include Pedant::RSpec::KnifeUtil
      include Pedant::RSpec::KnifeUtil::Role

      let(:command) { "knife role bulk delete '^pedant-role-' -c #{knife_config} --yes" }
      let(:roles)   { %w(pedant-role-0 pedant-role-1 pedant-master) }
      after(:each)  { roles.each(&delete_role!) }

      let(:create_role!) { ->(n) { knife "role create #{n} -c #{knife_config} -d #{role_description}" } }
      let(:delete_role!) { ->(n) { knife "role delete #{n} -c #{knife_config} --yes" } }

      context 'as an admin' do
        let(:requestor) { knife_admin }

        it 'should succeed' do
          pending "Roles are not being bulk deleted for some reason, despite having been created" do
            roles.each(&create_role!)

            # Runs knife role list
            should have_outcome :status => 0, :stdout => /Deleted role pedant-role-0\s+Deleted role pedant-role-1/
          end
        end
      end

    end
  end
end
