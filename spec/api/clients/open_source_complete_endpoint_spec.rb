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

require 'pedant/rspec/open_source_client_util'
require 'pedant/rspec/validations'

# Since we've already got an open-source only test spec for the
# clients endpoint, and since many of the operations that can be done
# are sensitive to the permissions of the requestor, we'll just
# integrate the permissions checking in with the rest of the tests.
require 'pedant/opensource/permission_checks'

describe "Open Source Client API endpoint", :platform => :open_source, :clients => true do

  def self.ruby?
    Pedant::Config.ruby_client_endpoint?
  end

  include Pedant::RSpec::OpenSourceClientUtil
  include Pedant::OpenSource::PermissionChecks

  # Just until we rename the requestors
  let(:admin_requestor){ admin_user }
  let(:normal_requestor){ normal_user }
  # TODO: Pull this out

  let(:validator_client){ Pedant::Client.new("#{open_source_validator_client_name}",
                                             "/etc/chef-server/#{open_source_validator_client_name}.pem")}
  let(:requestor){ admin_requestor }
  let(:client_name){pedant_admin_client_name}

  shared_context 'non-admin clients cannot perform operation' do
    let(:not_allowed_response){fail 'Please define not_allowed_response'}

    context 'as a non-admin client' do
      let(:requestor){normal_requestor}
      it 'is not allowed' do
        should look_like not_allowed_response
      end
    end

    context 'as a validator client' do
      let(:requestor){validator_client}
      it 'is not allowed' do
        should look_like not_allowed_response
      end
    end
  end

  def self.non_admin_clients_cannot_update
    include_context 'non-admin clients cannot perform operation' do
      let(:not_allowed_response){update_client_as_non_admin_response}
    end
  end

  def self.non_admin_clients_cannot_delete
    include_context 'non-admin clients cannot perform operation' do
      let(:not_allowed_response){delete_client_as_non_admin_response}
    end
  end


  # Other "container" endpoints are tested with and without items
  # already in the system, but there are always clients present in the
  # system, so we don't make that distinction.

  context 'GET /clients' do
    let(:request_method) { :GET }
    let(:request_url)    { clients_url }

    # TODO: Do this when we fix the look_like matcher
    # include_context 'permission checks' do
    #   let(:admin_response){fetch_prepopulated_clients_success_response}
    #   let(:non_admin_response){forbidden_response}
    # end

    context 'as an admin client' do
      let(:requestor){admin_requestor}
      it 'should return a list of name/url mappings for all clients' do
        should look_like(fetch_prepopulated_clients_success_response)
      end
    end
  end

  context 'POST /clients' do
    include Pedant::RSpec::Validations::Create

    let(:request_method)  { :POST }
    let(:request_url)     { clients_url }
    let(:request_payload) { default_client_attributes }

    let(:client_name) { unique_name("testclient") }
    let(:client_is_admin) { false }
    let(:default_client_attributes) do
      {
        "name" => client_name,
        "admin" => client_is_admin
      }
    end

    # useful for checking the result of a create operation
    # TODO: Refactor to resource_url
    let(:client_url) { api_url("/clients/#{client_name}") }

    let(:expected_response) { resource_created_full_response }
    let(:created_resource) { { "uri" => resource_url } }
    let(:resource_url) { client_url }
    let(:persisted_resource_response) { get(resource_url, superuser) }
    let(:default_resource_attributes) { default_client_attributes }
    let(:required_attributes) { default_client_attributes.except('admin').except('private_key') }

    after :each do
      begin
        delete_client(admin_requestor, client_name)
      rescue URI::InvalidURIError
        # ok, since some bad names can result in bad URLs
      end
    end

    context 'when validating' do
      context 'when updating public_key' do
        let(:request_payload) { required_attributes.with('public_key', public_key) }
        let(:updated_resource) { required_attributes.with('public_key', public_key) }
        let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
        let(:public_key) { private_key.public_key.to_s }
        let(:updated_requestor) { Pedant::Client.new(client_name, private_key, platform: platform, preexisting: false) }
        let(:updated_response) { http_200_response.with(:body, updated_resource) }


        should_respond_with 201, 'and update the user' do
          parsed_response['public_key'].should_not be_nil
          parsed_response.member?('private_key').should be_false # Make sure private_key is not returned at all

          # Now verify that you can retrieve it again
          persisted_resource_response.should look_like updated_response

          # Verify that we can use the new credentials
          get(resource_url, updated_requestor).should look_like updated_response
        end
      end # when setting private_key to true
    end

    context 'valid requests of various types to create a client' do
      context 'with a "normal" non-admin client payload' do
        it 'creates a new non-admin client' do
          should look_like create_client_success_response

          # Ensure it is a non-admin
          get(client_url, requestor) do |response|
            parse(response)["admin"].should be_false
          end
        end
      end

      context 'with a "normal" admin client payload' do
        let(:client_is_admin){true}
        it 'creates a new admin client' do
          should look_like create_client_success_response

          # Ensure it is an admin
          get(client_url, requestor) do |response|
            parse(response)["admin"].should be_true
          end
        end
      end

      context 'with a valid name' do
        ['pedanttestingclient', 'pedanttestingclient123', 'pedant_testing_client', 'pedant.testing.client'].each do |n|
          context "like '#{n}'" do
            let(:client_name){n}
            it 'succeeds' do
              should look_like create_client_success_response
            end
          end
        end
      end # valid names

      context 'without an admin flag' do
        let(:request_payload) do {"name" => client_name} end
        it 'succeeds, and a non-admin client is created' do
          request_payload.should_not have_key 'admin'
          should look_like create_client_success_response

          # Ensure it's not an admin
          get(client_url, requestor) do |response|
            parse(response)["admin"].should be_false
          end
        end
      end
    end

    context 'invalid requests of various types to create a client' do
      context 'with an invalid name' do
        ['pedant$testing$client', 'pedant testing client', 'pedant{testing}client'].each do |n|
          context "like '#{n}'" do
            let(:client_name){n}
            it 'fails' do
              should look_like create_client_bad_name_failure_response
            end
          end
        end
      end # invalid names

      context 'with a non-boolean admin flag' do
        let(:request_payload) do {"name" => client_name, "admin" => "sure, why not?"} end
        it 'fails' do
          should look_like create_client_failure_response
        end
      end

      # Bah... creates a dud record in CouchDB on Ruby Server
      context 'with an empty payload', :pending => ruby?  do
        let(:request_payload){{}}
        it 'fails' do
          should look_like create_client_no_name_failure_response
        end
      end

      # Bah... creates a dud record in CouchDB on Ruby Server
      context 'with no name', :pending => ruby?  do
        let(:request_payload){{"admin" => false}}
        it 'fails' do
          should look_like create_client_no_name_failure_response
        end
      end
    end

    context 'creation of an existing client' do
      include_context 'with temporary testing client'

      it 'is a conflict' do
        should look_like create_client_conflict_response
      end
    end

    context 'as different kinds of clients' do

      def self.should_be_able_to_create_client(is_admin=false)
        context "creating #{is_admin ? 'an admin' : 'a non-admin'} client" do
          let(:request_payload){{"name" => client_name, "admin" => is_admin}}
          it "succeeds" do
            # It should be created
            should look_like create_client_success_response
            # The new client can be retrieved (using admin_requestor
            # because validators can't retrieve clients!)
            get(client_url, admin_requestor).should look_like (is_admin ? fetch_admin_client_success_response : fetch_nonadmin_client_success_response)
          end
        end
      end

      def self.should_not_be_able_to_create_client(is_admin=false)
        context "creating #{is_admin ? 'an admin' : 'a non-admin'} client" do
          let(:request_payload){{"name" => client_name, "admin" => is_admin}}
          it 'fails' do
            # It should not be created
            should look_like create_client_as_non_admin_response
            # Nothing new should have been created (using
            # admin_requestor because non-admin clients can't
            # retrieve any client but themselves)
            get(client_url, admin_requestor).should look_like client_not_found_response
          end
        end
      end

      context 'as an admin client' do
        let(:requestor){admin_requestor}
        should_be_able_to_create_client(false)
        should_be_able_to_create_client(true)
      end

      context 'as a non-admin client' do
        let(:requestor){normal_requestor}
        should_not_be_able_to_create_client(false)
        should_not_be_able_to_create_client(true)
      end

      context 'as a validator client' do
        let(:requestor){validator_client}
        should_be_able_to_create_client(false)
        should_not_be_able_to_create_client(true)
      end
    end

    respects_maximum_payload_size

  end

  should_not_allow_method :PUT,    '/clients'
  should_not_allow_method :DELETE, '/clients'

  context 'GET' do
    let(:request_method) { :GET }
    let(:request_url)    { named_client_url }

    context 'an admin client' do
      let(:client_name){pedant_admin_client_name}
      it 'returns the client' do
        should look_like fetch_admin_client_success_response
      end
    end
    context 'a non-admin client' do
      let(:client_name){pedant_nonadmin_client_name}
      it 'returns a non-admin client' do
        should look_like fetch_nonadmin_client_success_response
      end
    end
    context 'a validator client' do
      let(:client_name){open_source_validator_client_name}
      it 'returns a validator client (which has validator=true)' do
        should look_like fetch_validator_client_success_response
      end
    end
    context 'a non-existent client' do
      let(:client_name){pedant_nonexistent_client_name}
      it 'returns a 404 not found' do
        should look_like client_not_found_response
      end
    end

    context 'as different kinds of clients' do
      context 'fetching an admin client' do
        include_context 'with temporary testing client' do
          let(:client_is_admin){true}
        end
        include_context 'permission checks' do
          let(:admin_response){ok_response}
          let(:non_admin_response){forbidden_response}
        end
      end

      context 'fetching a non-admin client' do
        include_context 'with temporary testing client' do
          let(:client_is_admin){false}
        end
        include_context 'permission checks' do
          let(:admin_response){ok_response}
          let(:non_admin_response){forbidden_response}
        end
      end

      context 'fetching a validator client' do
        let(:client_name){open_source_validator_client_name}
        include_context 'permission checks' do
          let(:admin_response){ok_response}
          let(:non_admin_response){forbidden_response}
        end
      end

      context 'fetching yourself as a non-admin' do
        let(:client_name){pedant_nonadmin_client_name}
        let(:requestor){normal_requestor}

        it 'is allowed (and is the only thing non-admin clients are allowed to retrieve)' do
          client_name.should eq requestor.name
          should look_like ok_response
        end
      end
    end

  end

  should_not_allow_method :POST, '/clients/pedant_test_client'

  context 'PUT /clients/<name>' do
    let(:request_method)  { :PUT }
    let(:request_url)     { named_client_url }
    let(:request_payload) { default_client_attributes }

    let(:client_url){api_url("/clients/#{client_name}")}

    let(:client_name) { unique_name("testclient") }
    let(:client_is_admin) { false }
    let(:default_client_attributes) do
      {
        "name" => client_name,
        "admin" => client_is_admin
      }
    end

    # useful for checking the result of a create operation
    # TODO: Refactor to resource_url
    let(:client_url) { api_url("/clients/#{client_name}") }

    let(:expected_response) { ok_response }
    let(:resource_url) { client_url }
    let(:persisted_resource_response) { get(resource_url, superuser) }
    let(:default_resource_attributes) { default_client_attributes }
    let(:required_attributes) { default_client_attributes.except('admin').except('private_key') }

    context 'when validating' do
      include_context 'with temporary testing client'

      context 'when updating public_key' do
        let(:request_payload) { required_attributes.with('public_key', public_key) }
        let(:updated_resource) { required_attributes.with('public_key', public_key) }
        let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
        let(:public_key) { private_key.public_key.to_s }
        let(:updated_requestor) { Pedant::Client.new(client_name, private_key, platform: platform, preexisting: false) }
        let(:updated_response) { http_200_response.with(:body, updated_resource) }


        should_respond_with 200, 'and update the user' do
          parsed_response['public_key'].should_not be_nil
          parsed_response.member?('private_key').should be_false # Make sure private_key is not returned at all

          # Now verify that you can retrieve it again
          persisted_resource_response.should look_like updated_response

          # Verify that we can use the new credentials
          get(resource_url, updated_requestor).should look_like updated_response
        end
      end # when setting private_key to true
    end

    context 'modifying a non-existent client' do
      let(:requestor) {admin_requestor}
      let(:client_name) {pedant_nonexistent_client_name}
      let(:request_payload) do
        {"name" => client_name}
      end
      it "returns a 404 not found" do
        should look_like client_not_found_response
      end
    end

    def self.test_property_change(property, payload_value, client_is_admin)
      # we'll change the private key, but this is reflected by a changed public key
      lookup_property = if property == "private_key"
                          "public_key"
                        else
                          property
                        end

      context_message = if property == "private_key"
                          "changing the private key of an #{client_is_admin ? 'an admin' : 'a non-admin'} client"
                        else
                          "changing the #{property} property of an #{client_is_admin ? 'an admin' : 'a non-admin'} client to '#{payload_value}'"
                        end

      context context_message do
        include_context 'with temporary testing client' do
          let(:client_admin){client_is_admin}
        end
        let(:request_payload) do
          {property.to_s => payload_value}
        end

        context 'as an admin client' do
          let(:requestor){admin_requestor}
          it 'succeeds' do
            # Record the initial value before the update
            initial_value = parse(get(client_url, requestor))[lookup_property]

            # Make the update
            # TODO: Should we test the body also?
            should look_like ok_response

            # Ensure that the value to be changed actually was changed
            final_value = parse(get(client_url, requestor))[lookup_property]
            initial_value.should_not eq final_value
          end
        end # admin client
        non_admin_clients_cannot_update
      end
    end # self.should_change_property

    test_property_change("admin", true, false)
    test_property_change("admin", false, true)
    test_property_change("private_key", true, false)
    test_property_change("private_key", true, true)

    context 'changing the name of a client' do
      include_context 'with temporary testing client'
      let(:request_payload) do
        {"name" => new_name}
      end

      context 'to an unclaimed name' do
        let(:new_name){unique_name("unclaimed_client")}
        before :each do
          # Ensures that no other client with this name exists
          get(api_url("/clients/#{new_name}"), admin_requestor).should look_like resource_not_found_response
        end
        after :each do
          delete_client(admin_requestor, new_name)
        end

        context 'as an admin client' do
          let(:requestor){admin_requestor}
          # Ruby Open Source is a bit broken in this respect; only
          # test with new Erchef hotness
          it 'can rename the client', :pending => ruby? do

            # Record the state of the client before making the change
            pre_change = parse(get(request_url, requestor))
            pre_change['name'].should eq client_name
            pre_change.delete 'name'
            pre_change.should_not have_key 'name'

            # Perform the update

            # we should not be able to find the client under the
            # original name
            should look_like({:status => 201})

            get(request_url, requestor).should look_like resource_not_found_response

            # we should be able to find the client under the new name
            post_change = parse(get(api_url("/clients/#{new_name}"), requestor))
            post_change['name'].should eq new_name
            post_change.delete 'name'
            post_change.should_not have_key 'name'

            # the new client should be the same as the old one, but with a different name
            post_change.should eq pre_change
          end
        end
        non_admin_clients_cannot_update
      end # to an unclaimed name

      context 'to the name of an existing client' do
        let(:preexisting_client_name){"preexisting_client"}

        before :each do
          add_client(admin_requestor, {'name' => preexisting_client_name, 'admin' => false})
        end
        after :each do
          delete_client(admin_requestor, preexisting_client_name)
        end

        let(:new_name){preexisting_client_name}

        # TODO: REMOVE THIS ON ERCHEF; WE DON'T USE COUCHDB
        def remove_couchdb_cruft(hash)
          hash.delete '_rev'
        end

        context 'as an admin client' do
          # Ruby Open Source returns a 200 instead of a 409 for the put operation, but doesn't actually make a change
          it 'raises a conflict', :pending => ruby? do
            # Record what the preexisting client looks like
            pre_change_preexisting = parse(get(api_url("/clients/#{preexisting_client_name}"), requestor))
            pre_change_preexisting['name'].should eq preexisting_client_name

            # Record what the testing client looks like
            pre_change_testing = parse(get(request_url, requestor))
            pre_change_testing['name'].should eq client_name

            # Make the update
            # TODO: Update this 'conflict response' with a more complete response once we're on Erchef
            # (Also, remove the pp call)
            should look_like conflict_response

            # Ensure the preexisting client remains unchanged
            post_change_preexisting = parse(get(api_url("/clients/#{preexisting_client_name}"), requestor))

            # TODO: REMOVE THESE ON ERCHEF; WE DON'T USE COUCHDB
            remove_couchdb_cruft pre_change_preexisting
            remove_couchdb_cruft post_change_preexisting

            post_change_preexisting.should eq pre_change_preexisting

            # Ensure the testing client remains unchanged
            post_change_testing = parse(get(request_url, requestor))

            # TODO: REMOVE THESE ON ERCHEF; WE DON'T USE COUCHDB
            remove_couchdb_cruft pre_change_testing
            remove_couchdb_cruft post_change_testing

            post_change_testing.should eq pre_change_testing
          end
        end # as an admin client

        non_admin_clients_cannot_update

      end # to the name of an existing client
    end #changing the name of a client

    context "changing a client's own name", :pending do
    end

    context 'promoting oneself to admin', :pending do
    end

    context 'promoting oneself to validator', :pending do
    end

    respects_maximum_payload_size

  end

  context 'DELETE /clients/<name>' do
    let(:request_method)  { :DELETE }
    let(:request_url)     { named_client_url }

    def self.should_have_proper_deletion_behavior(deleted_client_is_admin=false)
      context "deleting #{deleted_client_is_admin ? 'an admin' : 'a non-admin'} client" do
        include_context 'with temporary testing client' do
          let(:client_is_admin){deleted_client_is_admin}
        end

        context 'as admin client' do
          let(:requestor){admin_requestor}
          # Admins should be able to delete a client whether it is admin or not
          it 'succeeds' do
            should look_like delete_client_success_response
          end
          # TODO: Does not test for the edge case of deleting the last admin client
          # TODO: Does not test for an admin deleting itself
        end
        non_admin_clients_cannot_delete
      end
    end

    should_have_proper_deletion_behavior(true)
    should_have_proper_deletion_behavior(false)

    context 'deleting a non-existent client' do
      let(:requestor) {admin_requestor}
      let(:client_name) {pedant_nonexistent_client_name}
      it "returns a 404 not found" do
        should look_like client_not_found_response
      end
    end

    context 'deleting a validator' do
      include_context 'with temporary testing client' do
        let(:client_validator){true}
      end
      it 'is allowed' do
        should look_like delete_client_success_response
      end
    end

  end
end
