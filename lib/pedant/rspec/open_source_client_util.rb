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

require 'pedant/request'
require 'rspec/core/shared_context'

module Pedant
  module RSpec
    module OpenSourceClientUtil
      extend ::RSpec::Core::SharedContext

      # When you include this context, 'client_name' is set to the
      # name of the testing client
      shared_context 'with temporary testing client' do
        let(:client_name){unique_name("temporary_client")}
        let(:client_admin){false}
        let(:client) do
          {
            "name" => client_name,
            "admin" => client_admin
          }
        end
        before :each do
          add_client(admin_requestor, client)
        end

        after :each do
          delete_client(admin_requestor, client_name)
        end
      end # shared context

      # TODO: Pull these from pedant config
      let(:open_source_validator_client_name){"chef-validator"}
      let(:open_source_webui_client_name){"chef-webui"}
      let(:webui_admin_client_name){"chef-webui"}
      let(:pedant_admin_client_name){Pedant.config.requestors[:clients][:admin][:name]}
      let(:pedant_nonadmin_client_name){Pedant.config.requestors[:clients][:non_admin][:name]}
      let(:pedant_nonexistent_client_name){"non-existent"}

      # These will be used all over the place
      let(:clients_url){api_url("/clients")}
      let(:client_name) { fail "Please specify a 'client_name' first" }
      let(:named_client_url){api_url("/clients/#{client_name}")}

      let(:fetch_prepopulated_clients_success_response) do
        {
          :status => 200,
          :body_exact => {
            open_source_validator_client_name => api_url("/clients/#{open_source_validator_client_name}"),
            pedant_admin_client_name => api_url("/clients/#{pedant_admin_client_name}"),
            pedant_nonadmin_client_name => api_url("/clients/#{pedant_nonadmin_client_name}"),
            webui_admin_client_name => api_url("/clients/#{webui_admin_client_name}")
          }
        }
      end

      # TODO: This is broken on the Ruby implementation; should be 405
      let(:incorrect_ruby_clients_resource_method_not_allowed_response) do
        {
          :status => 404,
          :body_exact => {
            "error" => ["No routes match the request: /clients"]
          }
        }
      end

      # TODO: This is broken on the Ruby implementation; should be 405
      let(:incorrect_ruby_named_client_resource_method_not_allowed_response) do
        {
          :status => 404,
          :body_exact => {
            "error" => ["No routes match the request: /clients/#{client_name}"]
          }
        }
      end

      let(:client_not_found_response) { resource_not_found_response }

      let(:update_clients_method_not_allowed_response) { incorrect_ruby_clients_resource_method_not_allowed_response }
      let(:delete_clients_method_not_allowed_response) { incorrect_ruby_clients_resource_method_not_allowed_response }

      let(:post_named_client_method_not_allowed_response) { incorrect_ruby_named_client_resource_method_not_allowed_response }

      let(:fetch_admin_client_success_response) do
        {
          :status => 200,
          :body_exact => new_client(client_name, true)
        }
      end
      let(:fetch_validator_client_success_response) do
        {
          :status => 200,
          :body_exact => new_client(client_name, false, true)
        }
      end
      let(:fetch_nonadmin_client_success_response) do
        {
          :status => 200,
          :body_exact => new_client(client_name, false)
        }
      end

      let(:delete_client_success_response) do
        {
          :status => 200,
          :body => {
            "name" => client_name
          }
        }
      end

      let(:delete_client_as_non_admin_response) { open_source_not_allowed_response }

      let(:create_client_success_response) do
        {
          :status => 201,
          :body_exact => {
            "uri" => named_client_url,
            "private_key" => /^-----BEGIN RSA PRIVATE KEY-----/,
            "public_key" => /^-----BEGIN PUBLIC KEY-----/
          }
        }
      end

      let(:create_client_bad_name_failure_response) do
        {
          :status => 400,
          :body_exact => {
            "error" => ["Invalid client name '#{client_name}' using regex: 'Malformed client name.  Must be A-Z, a-z, 0-9, _, -, or .'."]
          }
        }
      end


      let(:create_client_no_name_failure_response) do
        {
          :status => 400,
          :body_exact => {
            "error" => ["Field 'name' missing"]
          }
        }
      end

      # should this be create_client_invalid_request_response ?
      let(:create_client_failure_response) do
        {
          :status => 400
        }
      end

      let(:create_client_conflict_response) do
        {
          :status => 409,
          :body_exact => {
            "error" => ["Client already exists"]
          }
        }
      end

      let(:create_client_as_non_admin_response) { open_source_not_allowed_response }
      let(:update_client_as_non_admin_response) { open_source_not_allowed_response }

      def new_client(name, admin=false, validator=false)
        {
          "name" => name,
          "chef_type" => "client",
          "json_class" => "Chef::ApiClient",
          "admin" => admin,
          "validator" => validator,
          "public_key" => /^(-----BEGIN RSA PUBLIC KEY-----|-----BEGIN PUBLIC KEY-----)/,
        }
      end

      def add_client(requestor, client)
        post(api_url("/clients"), requestor, :payload => client)
      end

      def delete_client(requestor, client_name)
        delete(api_url("/clients/#{client_name}"), requestor)
      end

    end
  end
end
