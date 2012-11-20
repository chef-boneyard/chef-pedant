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

require 'pedant/json'
require 'pedant/request'
require 'rspec/core/shared_context'
require 'openssl'

module Pedant
  module RSpec
    module UserUtil
      extend ::RSpec::Core::SharedContext
      extend ::Pedant::Concern

      include Pedant::JSON
      include Pedant::Request

      let(:user_collection_url) { api_url "/users" }
      let(:authenticate_user_url) { api_url "/authenticate_user" }
      let(:default_user_password) { 'opensesame123' }
      let(:default_user_attributes) do
          {
            "name" => default_user_name,
            "password" => default_user_password,
            "admin" => true
          }
      end

      def create_user(attributes, requestor)
        post(user_collection_url, requestor, payload: attributes)
      end

      def authenticate_user(name, password)
        r = parse(post(authenticate_user_url, superuser, payload: { 'name' => name, 'password' => password }))
        fail 'Something went wrong while authenticating a user' if r['verified'].nil?
        r['verified']
      end

      def delete_user(user_name, requestor = superuser)
        delete(api_url("/users/#{user_name}"), requestor)
      end


      # TODO: are we leaving behind a bunch of group cruft in CouchDB each
      # time we run a test?  Check out the groups of the org!

      def group_in_org(group_name)
        response = get(api_url("/groups/#{group_name}"), superuser)
        response.code == 200
      end

      def member_of_group(user, group_name)
        response = get(api_url("/groups/#{group_name}"), superuser)
        group_info = parse(response)
        group_info["actors"].include?(user.name)
      end

      def associated_with_org(user)
        response = get(api_url("/users"), superuser)
        user_info = parse(response)

        # here's what should come back:
        #  [{"user"=>{"username"=>"pedant-admin"}},
        #   {"user"=>{"username"=>"pedant-normal"}}]
        #

        user_info.any? do |user_item|
          user_item["user"]["username"] == user.name
        end

      end

      module ClassMethods
        def should_generate_new_keys
          context 'when setting private_key to true' do
            let(:request_payload) { required_attributes.with('private_key', true) }
            let(:new_public_key) { parsed_response['public_key'] }
            let(:updated_resource) { required_attributes.with('public_key', new_public_key) }

            should_respond_with 200, 'and update the user' do
              parsed_response['private_key'].should_not be_nil

              # Now verify that you can retrieve it again
              persisted_resource_response.should look_like http_200_response.with(:body, updated_resource)
              authenticate_user(default_user_name, default_user_password).should be_true
            end
          end # when setting private_key to true
        end

        def should_update_public_key
          context 'when updating public_key' do
            let(:request_payload) { required_attributes.with('public_key', public_key) }
            let(:updated_resource) { required_attributes.with('public_key', public_key) }
            let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
            let(:public_key) { private_key.public_key.to_s }
            let(:updated_requestor) { Pedant::User.new(test_user, private_key, platform: platform, preexisting: false) }
            let(:updated_response) { http_200_response.with(:body, updated_resource) }


            should_respond_with 200, 'and update the user' do
              parsed_response['public_key'].should_not be_nil

              # Now verify that you can retrieve it again
              persisted_resource_response.should look_like updated_response
              authenticate_user(default_user_name, default_user_password).should be_true

              # Verify that we can use the new credentials
              get(resource_url, updated_requestor).should look_like updated_response
            end
          end # when setting private_key to true
        end

        def should_update_without_password
          context 'without a password' do
            let(:request_payload) { required_attributes }
            let(:default_resource_attributes) { default_user_attributes }
            let(:updated_resource) { required_attributes }

            should_respond_with 200, 'and preserve the password' do
              parsed_response['password'].should be_nil
              parsed_response['salt'].should be_nil

              # Now verify that you can retrieve it again
              persisted_resource_response.should look_like http_200_response.with(:body, updated_resource)
              authenticate_user(default_user_name, default_user_password).should be_true
            end
          end # when setting a password
        end

        def should_update_password
          context 'when setting a password' do
            let(:new_password) { SecureRandom.hex(10) }
            let(:request_payload) { required_attributes.with('password', new_password) }
            let(:default_resource_attributes) { default_user_attributes }
            let(:new_public_key) { parsed_response['public_key'] }
            let(:updated_resource) { required_attributes }

            should_respond_with 200, 'and update the user' do
              parsed_response['password'].should be_nil
              parsed_response['salt'].should be_nil

              # Now verify that you can retrieve it again
              persisted_resource_response.should look_like http_200_response.with(:body, updated_resource)
              authenticate_user(default_user_name, new_password).should be_true
            end
          end # when setting a password
        end
      end # ClassMethods

    end # UserUtil
  end # RSpec
end # Pedant
