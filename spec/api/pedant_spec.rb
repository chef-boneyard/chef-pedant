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

# Pedant self-diagnostic tests
#
# This spec results from the fragility of using let() with before(:all) blocks
# The work-around uses shared() for anything referenced in a before(:all) block.
# These tests make sure shared() works, and will have some canary tests to make
# sure what should be in shared() blocks do not slip in.

require 'pedant/rspec/role_util'

describe 'Pedant Self-Diagnostic', :pedantic do
  context 'with shared() and let()' do
    context 'before(:all)' do
      before(:all) { shared_var } # Reference foo in noop

      # If :foo is declared with let(), the examples here will fail.
      shared(:shared_var) { :parent }
      let(:let_var)       { :parent }

      context 'within a child context' do
        let(:shared_var) { :child }
        let(:let_var)    { :child }

        it 'should use the child shared_var' do
          shared_var.should eql :child
        end

        it 'should use the child let_var' do
          let_var.should eql :child
        end
      end

      it 'should use parent shared_var' do
        shared_var.should eql :parent
      end

      it 'should use parent let_var' do
        let_var.should eql :parent
      end
    end
  end

  context 'Integration Users' do
    include Pedant::RSpec::RoleUtil

    shared(:existing_role) { 'web' }

    # If any of these fail, it is because the variable should be shared(), not let()
    def self.should_be_sharing(shared_var_name)
      context "with #{shared_var_name}" do
        before(:all) { send(shared_var_name); add_role(admin_user, new_role(existing_role)) }
        after(:all)  { delete_role(admin_user, existing_role) }

        let(:let_var)       { :parent }

        context 'within a child context' do
          let(:let_var)    { :child }

          it 'should use the child let_var' do
            let_var.should eql :child
          end
        end

        it 'should use parent let_var' do
          let_var.should eql :parent
        end
      end
    end # .should_be_sharing

    should_be_sharing :admin_user
    should_be_sharing :normal_user
    should_be_sharing :outside_user
    should_be_sharing :superuser
  end

  context 'Matchers' do
    describe 'have_entry' do
      let(:value) { 1 }

      it 'should accept an integer' do
        { a: 1, b: 1 }.should have_entry [ :a, 1 ]
      end

      it 'should accept a String' do
        { a: 'Foo', b: 'Bar' }.should have_entry [ :a, 'Foo' ]
      end


      it 'should accept an Array' do
        { a: [1,2,3] }.should have_entry [ :a, [2,3,1] ]
      end

      it 'should accept an Array of Hashes' do
        { a: [{b: 2}, {c: 3}] }.should have_entry [ :a, [{c: 3}, {b:2}] ]
      end

      it 'should accept a Hash' do
        { a: { b: 3 } }.should have_entry [ :a, {b: 3} ]
      end

      it 'should accept a Proc' do
        { a: 1 }.should have_entry [ :a, ->(a) { a == 1 } ]
        { a: 1 }.should_not have_entry [ :a, ->(a) { a == 2 } ]
      end

      it 'should accept a closure' do
        { a: value }.should have_entry [ :a, ->(a) { a == value } ]
      end
    end
  end
end
