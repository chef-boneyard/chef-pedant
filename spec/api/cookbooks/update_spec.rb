# -*- coding: utf-8 -*-
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

require 'pedant/rspec/cookbook_util'

# FIXME For /cookbooks/NAME/VERSION tests we have a limited checking
# on the GET afterwards to do validation of data on the server.  Since
# we can't match the payload against one with dynamically generated
# URLs we're only checking for the return code.
#
# We need to come back (along with adding tests for the GET case
# explicitly in read_spec.rb) and update the tests marked with TODO
# to actually match on the generate response body as well
#

describe "Cookbooks API endpoint", :cookbooks do
  include Pedant::RSpec::CookbookUtil

  def self.ruby?
    Pedant::Config.ruby_cookbook_endpoint?
  end
  # When testing against the Ruby version of this endpoint the
  # 'cookbook-to-be-modified' cookbook which is created (and deleted) in the
  # 'cookbook_spec' is leaking into this spec. Most likely caused by some Couch
  # shenanigans...we'll just mark the tests as pending on Ruby.
  context "PUT /cookbooks/<name>/<version> [update]", :pending => ruby? do

    let(:request_method){:PUT}
    shared(:requestor){admin_user}
    let(:request_url) { named_cookbook_url }
    let(:cookbook_name) { "cookbook-to-be-modified" }
    let(:cookbook_version) { self.class.cookbook_version }
    let(:fetched_cookbook) { new_cookbook(cookbook_name, cookbook_version) }
    let(:original_cookbook) { new_cookbook(cookbook_name, cookbook_version) }

    # This requires deep dup
    let(:updated_cookbook) do
      original_cookbook.dup.tap do |cookbook|
        cookbook["metadata"] = cookbook["metadata"].dup.tap { |c| c["description"] = "hi there #{rand(10000)}" }
      end
    end

    # TODO: KLUDGE: Cop-out, because I am too tired to refactor the macros correctly
    def self.cookbook_version
      "11.2.3"
    end

    before(:each) {
      make_cookbook(admin_user, cookbook_name, cookbook_version)
    }

    after(:each) {
      delete_cookbook(admin_user, cookbook_name, cookbook_version)
    }

    if erlang?
      respects_maximum_payload_size
    end

    context "with permissions for" do
      it "admin user returns 200" do
        payload = new_cookbook(cookbook_name, cookbook_version)
        metadata = payload["metadata"]
        metadata["description"] = "hi there"
        payload["metadata"] = metadata

        put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user, :payload => payload) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload["_rev"] = /.*/
          end
          response.
            should look_like({
                               :status => 200,
                               :body_exact => payload
                             })
        end

        # verify change happened
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload.delete("_rev")
          end
          response.
            should look_like({
                               :status => 200,
                               :body_exact => payload
                             })
        end
      end # it admin user returns 200

      context 'as a user outside of the organization' do
        let(:expected_response) { unauthorized_access_credential_response }

        it "should respond with 403 (\"Forbidden\") and does not update cookbook" do
          put(request_url, outside_user, :payload => updated_cookbook) do |response|
            response.should look_like expected_response
          end

          should_not_be_updated
        end # it outside user returns 403 and does not update cookbook
      end

      context 'with invalid user' do
        let(:expected_response) { invalid_credential_exact_response }

        it "returns 401 and does not update cookbook" do
          put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"), invalid_user, :payload => updated_cookbook) do |response|
            response.should look_like expected_response
          end

          # Verified change did not happen
          get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"), admin_user) do |response|
            response.
              should look_like({
              :status => 200,
              :body_exact => original_cookbook
            })
          end
        end # it invalid user returns 401 and does not update cookbook
      end # with invalid user
    end # context with permissions for

    context "for checksums" do
      include Pedant::RSpec::CookbookUtil

      let(:sandbox) { create_sandbox(files) }
      let(:upload) { ->(file) { upload_to_sandbox(file, sandbox) } }
      let(:files) { (0..3).to_a.map { Pedant::Utility.new_random_file } }

      let(:committed_files) do
        files.each(&upload)
        commit_sandbox(sandbox)
      end

      let(:checksums) { parse(committed_files)["checksums"] }

      it "adding all new checksums should succeed" do
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["files"] = [{"name" => "name1", "path" => "path/name1",
                              "checksum" => checksums[0],
                              "specificity" => "default"},
                            {"name" => "name2", "path" => "path/name2",
                              "checksum" => checksums[1],
                              "specificity" => "default"},
                            {"name" => "name3", "path" => "path/name3",
                              "checksum" => checksums[2],
                              "specificity" => "default"},
                            {"name" => "name4", "path" => "path/name4",
                              "checksum" => checksums[3],
                              "specificity" => "default"}]

        verify_checksum_cleanup(:files) do

          put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user, :payload => payload) do |response|

            if (ruby?)
              # Don't really care about this; going away in erchef
              payload["_rev"] = /.*/
            end
            response.
              should look_like({
                                 :status => 200,
                                 :body_exact => payload
                               })
          end

          # verify change happened
          # TODO make this match on body when URLs are parsable
          get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user) do |response|
            if (ruby?)
              # Don't really care about this; going away in erchef
              payload.delete("_rev")
            end
            response.
              should look_like({
                                 :status => 200
                                 #:body_exact => payload
                               })
          end
        end # verify_checksum_cleanup

      end # it adding all new checksums should succeed

      it "should return url when adding checksums (if ruby endpoint)" do
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["files"] = [{"name" => "name1", "path" => "path/name1",
                              "checksum" => checksums[0],
                              "specificity" => "default"},
                            {"name" => "name2", "path" => "path/name2",
                              "checksum" => checksums[1],
                              "specificity" => "default"}]

        put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user, :payload => payload) do |response|

          if (ruby?)
            # Don't really care about this; going away in erchef
            payload["_rev"] = /.*/
          end
          response.
            should look_like({
                               :status => 200,
                               :body_exact => payload
                             })
        end

        # verify change happened
        # TODO make this match on body when URLs are parsable
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload.delete("_rev")
            payload["files"] = [{"name" => "name1", "path" => "path/name1",
                                  "checksum" => checksums[0],
                                  "specificity" => "default"},
                                {"name" => "name2", "path" => "path/name2",
                                  "checksum" => checksums[1],
                                  "specificity" => "default"}]
          end
          response.
            should look_like({
                               :status => 200
                              # :body_exact => payload
                             })
        end
      end # it should return url when adding checksums (if ruby endpoint)

      it "adding invalid checksum should fail" do
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["files"] = [{"name" => "name1", "path" => "path/name1",
                              "checksum" => checksums[0],
                              "specificity" => "default"},
                            {"name" => "name2", "path" => "path/name2",
                              "checksum" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                              "specificity" => "default"}]

        put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user, :payload => payload) do |response|

          error = ["Manifest has checksum aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa but it hasn't yet been uploaded"]
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload["_rev"] = /.*/
            error = ["Manifest has checksum aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa (path path/name2) but it hasn't yet been uploaded"]
          end
          response.
            should look_like({
                               :status => 400,
                               :body_exact => {
                                 "error" => error
                               }
                             })
        end

        # Verify change did not happen
        payload.delete("files")

        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload.delete("_rev")
          end
          response.
            should look_like({
                               :status => 200,
                               :body_exact => payload
                             })
        end
      end # it adding invalid checksum should fail

      it "deleting all checksums should succeed" do
        delete_cookbook(admin_user, cookbook_name, cookbook_version)
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["files"] = [{"name" => "name1", "path" => "path/name1",
                              "checksum" => checksums[0],
                              "specificity" => "default"},
                            {"name" => "name2", "path" => "path/name2",
                              "checksum" => checksums[1],
                              "specificity" => "default"},
                            {"name" => "name3", "path" => "path/name3",
                              "checksum" => checksums[2],
                              "specificity" => "default"},
                            {"name" => "name4", "path" => "path/name4",
                              "checksum" => checksums[3],
                              "specificity" => "default"}]
        upload_cookbook(admin_user, cookbook_name, cookbook_version, payload)

        # Verified initial cookbook
        # TODO make this match on body when URLs are parsable
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload.delete("_rev")
          end

          response.
            should look_like({
                               :status => 200
                               #:body_exact => payload
                             })
        end

        verify_checksum_cleanup(:files) do

          payload.delete("files")
          put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user, :payload => payload) do |response|

            if (ruby?)
              # Don't really care about this; going away in erchef
              payload["_rev"] = /.*/
            end
            response.
              should look_like({
                                 :status => 200,
                                 :body_exact => payload
                               })
          end

          # verify change happened
          # TODO make this match on body when URLs are parsable
          get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user) do |response|
            if (ruby?)
              # Don't really care about this; going away in erchef
              payload.delete("_rev")
            end
            response.
              should look_like({
                                 :status => 200
                                 #:body_exact => payload
                               })
          end
        end # verify_checksum_cleanup

      end # it deleting all checksums should succeed

      it "deleting some checksums should succeed" do
        delete_cookbook(admin_user, cookbook_name, cookbook_version)
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["files"] = [{"name" => "name1", "path" => "path/name1",
                              "checksum" => checksums[0],
                              "specificity" => "default"},
                            {"name" => "name2", "path" => "path/name2",
                              "checksum" => checksums[1],
                              "specificity" => "default"},
                            {"name" => "name3", "path" => "path/name3",
                              "checksum" => checksums[2],
                              "specificity" => "default"},
                            {"name" => "name4", "path" => "path/name4",
                              "checksum" => checksums[3],
                              "specificity" => "default"}]

        upload_cookbook(admin_user, cookbook_name, cookbook_version, payload)

        # Verified initial cookbook
        # TODO make this match on body when URLs are parsable
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload.delete("_rev")
          end
          response.
            should look_like({
                               :status => 200
                               #:body_exact => payload
                             })
        end

        verify_checksum_cleanup(:files) do

          payload["files"] = [{"name" => "name1", "path" => "path/name1",
                                "checksum" => checksums[0],
                                "specificity" => "default"},
                              {"name" => "name2", "path" => "path/name2",
                                "checksum" => checksums[1],
                                "specificity" => "default"}]
          put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user, :payload => payload) do |response|

            if (ruby?)
              # Don't really care about this; going away in erchef
              payload["_rev"] = /.*/
            end
            response.
              should look_like({
                                 :status => 200,
                                 :body_exact => payload
                               })
          end

          # verify change happened
          # TODO make this match on body when URLs are parsable
          get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user) do |response|
            if (ruby?)
              # Don't really care about this; going away in erchef
              payload.delete("_rev")
            end
            response.
              should look_like({
                                 :status => 200
                                 #:body_exact => payload
                               })
          end
        end # verify_checksum_cleanup
      end # it deleting some checksums should succeed

      it "changing all different checksums should succeed" do
        delete_cookbook(admin_user, cookbook_name, cookbook_version)
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["files"] = [{"name" => "name1", "path" => "path/name1",
                              "checksum" => checksums[0],
                              "specificity" => "default"},
                            {"name" => "name2", "path" => "path/name2",
                              "checksum" => checksums[1],
                              "specificity" => "default"}]
        upload_cookbook(admin_user, cookbook_name, cookbook_version, payload)

        # Verified initial cookbook
        # TODO make this match on body when URLs are parsable
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload.delete("_rev")
          end
          response.
            should look_like({
                               :status => 200
                               #:body_exact => payload
                             })
        end

        verify_checksum_cleanup(:files) do

          payload["files"] = [{"name" => "name3", "path" => "path/name3",
                                "checksum" => checksums[2],
                                "specificity" => "default"},
                              {"name" => "name4", "path" => "path/name4",
                                "checksum" => checksums[3],
                                "specificity" => "default"}]
          put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user, :payload => payload) do |response|

            if (ruby?)
              # Don't really care about this; going away in erchef
              payload["_rev"] = /.*/
            end
            response.
              should look_like({
                                 :status => 200,
                                 :body_exact => payload
                               })
          end

          # verify change happened
          # TODO make this match on body when URLs are parsable
          get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user) do |response|
            if (ruby?)
              # Don't really care about this; going away in erchef
              payload.delete("_rev")
            end
            response.
              should look_like({
                                 :status => 200
                                 #:body_exact => payload
                               })
          end
        end # verify_checksum_cleanup
      end # it changing all different checksums should succeed

      it "changing some different checksums should succeed" do
        delete_cookbook(admin_user, cookbook_name, cookbook_version)
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["files"] = [{"name" => "name1", "path" => "path/name1",
                              "checksum" => checksums[0],
                              "specificity" => "default"},
                            {"name" => "name2", "path" => "path/name2",
                              "checksum" => checksums[1],
                              "specificity" => "default"},
                            {"name" => "name3", "path" => "path/name3",
                              "checksum" => checksums[2],
                              "specificity" => "default"}]
        upload_cookbook(admin_user, cookbook_name, cookbook_version, payload)

        # Verified initial cookbook
        # TODO make this match on body when URLs are parsable
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload.delete("_rev")
          end
          response.
            should look_like({
                               :status => 200
                               #:body_exact => payload
                             })
        end

        verify_checksum_cleanup(:files) do

          payload["files"] = [{"name" => "name2", "path" => "path/name2",
                                "checksum" => checksums[1],
                                "specificity" => "default"},
                              {"name" => "name3", "path" => "path/name3",
                                "checksum" => checksums[2],
                                "specificity" => "default"},
                              {"name" => "name4", "path" => "path/name4",
                                "checksum" => checksums[3],
                                "specificity" => "default"}]
          put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user, :payload => payload) do |response|

            if (ruby?)
              # Don't really care about this; going away in erchef
              payload["_rev"] = /.*/
            end
            response.
              should look_like({
                                 :status => 200,
                                 :body_exact => payload
                               })
          end

          # verify change happened
          # TODO make this match on body when URLs are parsable
          get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user) do |response|
            if (ruby?)
              # Don't really care about this; going away in erchef
              payload.delete("_rev")
            end
            response.
              should look_like({
                                 :status => 200
                                 #:body_exact => payload
                               })
          end
        end # verify_checksum_cleanup
      end # it changing some different checksums should succeed

      it "changing to invalid checksums should fail" do
        delete_cookbook(admin_user, cookbook_name, cookbook_version)

        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["files"] = [{"name" => "name1", "path" => "path/name1",
                              "checksum" => checksums[0],
                              "specificity" => "default"},
                            {"name" => "name2", "path" => "path/name2",
                              "checksum" => checksums[1],
                              "specificity" => "default"},
                            {"name" => "name3", "path" => "path/name3",
                              "checksum" => checksums[2],
                              "specificity" => "default"}]
        upload_cookbook(admin_user, cookbook_name, cookbook_version, payload)

        # Verified initial cookbook
        # TODO make this match on body when URLs are parsable
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload.delete("_rev")
          end
          response.
            should look_like({
                               :status => 200
                               #:body_exact => payload
                             })
        end

        payload["files"] = [{"name" => "name2", "path" => "path/name2",
                              "checksum" => checksums[1],
                              "specificity" => "default"},
                            {"name" => "name3", "path" => "path/name3",
                              "checksum" => checksums[2],
                              "specificity" => "default"},
                            {"name" => "name4", "path" => "path/name4",
                              "checksum" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                              "specificity" => "default"}]
        put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user, :payload => payload) do |response|

          error = ["Manifest has checksum aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa but it hasn't yet been uploaded"]
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload["_rev"] = /.*/
            error = ["Manifest has checksum aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa (path path/name4) but it hasn't yet been uploaded"]
          end
          response.
            should look_like({
                               :status => 400,
                               :body_exact => {
                                 "error" => error
                               }
                             })
        end

        # verify change did not happen
        payload["files"] = [{"name" => "name1", "path" => "path/name1",
                              "checksum" => checksums[0],
                              "specificity" => "default"},
                            {"name" => "name2", "path" => "path/name2",
                              "checksum" => checksums[1],
                              "specificity" => "default"},
                            {"name" => "name3", "path" => "path/name3",
                              "checksum" => checksums[2],
                              "specificity" => "default"}]

        # TODO make this match on body when URLs are parsable
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload.delete("_rev")
          end
          response.
            should look_like({
                               :status => 200
                               #:body_exact => payload
                             })
        end
      end # it changing to invalid checksums should fail
    end # context for checksums

    context "for frozen?" do
      before(:each) do
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["frozen?"] = true

        put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user, :payload => payload) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload["_rev"] = /.*/
          end
          response.
            should look_like({
                               :status => 200,
                               :body_exact => payload
                             })
        end
      end # before :each

      it "can set frozen? to true" do
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["frozen?"] = true
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          response.
            should look_like({
                               :status => 200,
                               :body_exact => payload
                             })
        end
      end # it can set frozen? to true

      it "can not edit cookbook when frozen? is set to true" do
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["frozen?"] = false
        metadata = payload["metadata"]
        metadata["description"] = "this is different"
        payload["metadata"] = metadata

        put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user, :payload => payload) do |response|
          response.
            should look_like({
                               :status => 409,
                               :body_exact => {
                                 "error" => ["The cookbook #{cookbook_name} at version #{cookbook_version} is frozen. Use the 'force' option to override."]
                               }
                             })
        end

        # Verify that change did not occur
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["frozen?"] = true
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          response.
            should look_like({
                               :status => 200,
                               :body_exact => payload
                             })
          end
      end # it can not edit cookbook when frozen? is set to true

      it "can override frozen? with force set to true" do
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["frozen?"] = false
        metadata = payload["metadata"]
        metadata["description"] = "this is different"
        payload["metadata"] = metadata

        put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}?force=true"),
            admin_user, :payload => payload) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload["_rev"] = /.*/
          end
          # You can modify things, but you can't unfreeze the cookbook
          payload["frozen?"] = true
          response.
            should look_like({
                               :status => 200,
                               :body_exact => payload
                             })
        end

        # Verify that change did occur
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          if (ruby?)
           payload.delete("_rev")
          end
          response.
            should look_like({
                               :status => 200,
                               :body_exact => payload
                             })
        end
      end # it can override frozen? with force set to true

      it "can not override frozen? with force set to false" do
        payload = new_cookbook(cookbook_name, cookbook_version)
        payload["frozen?"] = false
        metadata = payload["metadata"]
        metadata["description"] = "this is different"
        payload["metadata"] = metadata

        put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}?force=false"),
            admin_user, :payload => payload) do |response|
          if (ruby?)
            # Don't really care about this; going away in erchef
            payload["_rev"] = /.*/
          end
          # You can modify things, but you can't unfreeze the cookbook
          payload["frozen?"] = true
          if (ruby?)
            # This is a bug in Ruby -- this shouldn't work, and we are
            # NOT duplicating this behavior in erlang
            response.
              should look_like({
                                 :status => 200,
                                 :body_exact => payload
                               })
          else
            response.
              should look_like({
                                 :status => 409,
                                 :body_exact => {
                                   "error" => ["The cookbook #{cookbook_name} at version #{cookbook_version} is frozen. Use the 'force' option to override."]
                                 }
                               })
          end
        end

        # Verify that change did occur
        get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
            admin_user) do |response|
          if (ruby?)
            payload.delete("_rev")
          else
            payload = new_cookbook(cookbook_name, cookbook_version)
            payload["frozen?"] = true
          end
          response.
            should look_like({
                               :status => 200,
                               :body_exact => payload
                             })
        end
      end # it can not override frozen? with force set to false
    end # context for frozen?

    context "when modifying data" do
      if ruby?
        # Not duplicating this for erlang; raise 400 instead
        it "changing name has very odd behavior" do
          # TODO: This seems very bad

          new_name = 'new_name'

          payload = new_cookbook(cookbook_name, cookbook_version)
          payload['name'] = new_name
          put(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user, :payload => payload) do |response|
            if (ruby?)
              # Ruby endpoint produces this, erlang should not
              payload["_rev"] = /.*/
            end
            response.
              should look_like({
                                 :status => 200,
                                 :body_exact => payload
                               })
          end

          # verify change happened

          # Old name is gone?
          get(api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
              admin_user) do |response|
            if (ruby?)
              payload.delete("_rev")
            end
            response.
              should look_like({
                                 :status => 404
                               })
          end

          # New name?
          get(api_url("/cookbooks/#{new_name}/#{cookbook_version}"),
              admin_user) do |response|
            if (ruby?)
              payload.delete("_rev")
            end
            response.
              should look_like({
                                 :status => 404
                               })
          end

          # Maybe a different new name?
          get(api_url("/cookbooks/"),
              admin_user) do |response|
            if (ruby?)
              payload.delete("_rev")
            end
            response.
              should look_like({
                                 :status => 200,
                                 :body_exact => {
                                   cookbook_name => {
                                     'url' => api_url("/cookbooks/#{cookbook_name}"),
                                     'versions' => [{
                                                      'url' => api_url("/cookbooks/#{cookbook_name}/#{cookbook_version}"),
                                                      'version' => cookbook_version
                                                    }]
                                   }
                                 }
                               })
          end

          # Wait, what?
          get(api_url("/cookbooks/#{cookbook_name}"),
              admin_user) do |response|
            if (ruby?)
              payload.delete("_rev")
            end
            response.
              should look_like({
                                 :status => 200
                               })
          end
        end # it changing name has very odd behavior
      end # if ruby?

      context "for cookbook_name" do
        if (ruby?)
          should_fail_to_change('cookbook_name', 'new_cookbook_name', 400,
                                'You said the cookbook was named new_cookbook_name, ' +
                                 'but the URL says it should be ' +
                                 'cookbook-to-be-modified.')
          should_fail_to_change('cookbook_name', :delete, 400,
                                'You said the cookbook was named , ' +
                                 'but the URL says it should be ' +
                                 'cookbook-to-be-modified.')

          [1, true, [], {}, 'with a space', '外国語'].each do |value|
            should_fail_to_change('cookbook_name', value, 400,
                                  "You said the cookbook was named #{value}, but the" +
                                   " URL says it should be cookbook-to-be-modified.")
          end
        else
          [1, true, [], {}].each do |value|
            should_fail_to_change('cookbook_name', value, 400, "Field 'cookbook_name' invalid")
          end
          ['new_cookbook_name', 'with a space', '外国語'].each do |value|
            should_fail_to_change('cookbook_name', value, 400, "Field 'cookbook_name' invalid")
          end
          should_fail_to_change('cookbook_name', :delete, 400, "Field 'cookbook_name' missing")
        end
      end # context for cookbook_name

      context "for json_class" do
        if (ruby?)
          update_should_crash_server('json_class', 'Chef::NonCookbook')
          should_fail_to_change('json_class', :delete, 400, "You didn't pass me a valid object!")
          update_should_crash_server('json_class', 1)
          update_should_crash_server('json_class', 'all wrong')
        else
          should_not_change('json_class', :delete, 'Chef::CookbookVersion')
          should_fail_to_change('json_class', 1, 400, "Field 'json_class' invalid")
          should_fail_to_change('json_class', 'Chef::NonCookbook', 400, "Field 'json_class' invalid")
          should_fail_to_change('json_class', 'all wrong', 400, "Field 'json_class' invalid")
        end
      end # context for json_class

      context "for chef_type" do
        should_not_change('chef_type', :delete, 'cookbook_version')
        if (ruby?)
          should_not_change('chef_type', 'not_cookbook', 'cookbook_version')
          should_not_change('chef_type', false, 'cookbook_version')
          should_not_change('chef_type', ['just any', 'old junk'], 'cookbook_version')
        else
          should_fail_to_change('chef_type', 'not_cookbook', 400, "Field 'chef_type' invalid")
          should_fail_to_change('chef_type', false, 400, "Field 'chef_type' invalid")
          should_fail_to_change('chef_type', ['just any', 'old junk'], 400, "Field 'chef_type' invalid")
        end
      end # context for chef_type

      context "for version" do
        should_change('version', :delete)
        if (ruby?)
          should_change('version', '0.0')
          should_change('version', 1)
          should_change('version', ['all', 'ignored'])
          should_change('version', {})
          should_change('version', 'something invalid')
        else
          error = "Field 'version' invalid"
          should_fail_to_change('version', 1, 400, error)
          should_fail_to_change('version', ['all', 'ignored'], 400, error)
          should_fail_to_change('version', {}, 400, error)

          error = "Field 'version' invalid"
          should_fail_to_change('version', '0.0', 400, error)
          should_fail_to_change('version', 'something invalid', 400, error)
        end
      end # context for version

      context "for collections" do
        ['attributes', 'definitions', 'files', 'libraries', 'providers', 'recipes',
         'resources', 'root_files', 'templates'].each do |segment|
          context "for #{segment}" do
            if (ruby?)
              update_should_crash_server(segment, 'foo')
              update_should_crash_server(segment, ['foo'])
            else
              should_fail_to_change(segment, 'foo', 400, "Field '#{segment}' invalid")
              error = "Invalid element in array value of '#{segment}'."
              should_fail_to_change(segment, ['foo'], 400, error)
            end
            should_change(segment, [])

            if (ruby?)
              error = "Manifest has checksum  (path ) but it hasn't yet been uploaded"
            end
            should_fail_to_change(segment, [{}, {}], 400, error)
            should_fail_to_change(segment, [{'foo' => 'bar'}], 400, error)
          end # context for #{segment}
        end # [loop over attributes, definitions, files, libraries, providers,
          #              recipes, resources, root_files, templates
      end # context for collections

      context "for other stuff" do
        should_change('frozen?', true)
        should_change('blah', 'bleargh')
      end # context for other stuff
    end # context when modifying data

    context "when modifying metadata" do
      if (ruby?)
        should_fail_to_change('metadata', {'new_name' => 'foo'}, 400, "You said the cookbook was version 0.0.0, but the URL says it should be #{cookbook_version}.")
      else
        should_fail_to_change('metadata', {'new_name' => 'foo'}, 400, "Field 'metadata.version' missing")
      end

      context "for name" do
        if (ruby?)
          ['new_name', :delete, 1, true, {}, [], 'invalid name', 'ダメよ'].each do |name|
            should_change_metadata('name', name)
          end
        else
          ['new_name', :delete].each do |name|
            should_change_metadata('name', name)
          end
          [[1, 'number'], [true, 'boolean'], [{}, 'object'],
           [[], 'array']].each do |error|
            json_error = "Field 'metadata.name' invalid"
            should_fail_to_change_metadata('name', error[0], 400, json_error)
          end
          ['invalid name', 'ダメよ'].each do |name|
            should_fail_to_change_metadata('name', name, 400, "Field 'metadata.name' invalid")
          end
        end
      end # context for name

      context "for description" do
        should_change_metadata('description', 'new description')
        should_change_metadata('description', :delete)
        if (ruby?)
          should_change_metadata('description', 1)
        else
          should_fail_to_change_metadata('description', 1, 400, "Field 'metadata.description' invalid")
        end
      end # context for description

      context "for long description" do
        should_change_metadata('long_description', 'longer description')
        should_change_metadata('long_description', :delete)
        if (ruby?)
          should_change_metadata('long_description', false)
        else
          should_fail_to_change_metadata('long_description', false, 400, "Field 'metadata.long_description' invalid")
        end
      end # context for long description

      context "for version" do
        if (ruby?)
          should_fail_to_change_metadata('version', '0.0', 400,
                                         'You said the cookbook was version 0.0, ' +
                                          "but the URL says it should be #{cookbook_version}.")
          should_fail_to_change_metadata('version', 'not a version', 400,
                                         'You said the cookbook was version ' +
                                          'not a version, ' +
                                          "but the URL says it should be #{cookbook_version}.")
          should_fail_to_change_metadata('version', :delete, 400,
                                         'You said the cookbook was version 0.0.0, ' +
                                          "but the URL says it should be #{cookbook_version}.")
          should_fail_to_change_metadata('version', 1, 400,
                                         'You said the cookbook was version 1, ' +
                                          "but the URL says it should be #{cookbook_version}.")
        else
          should_fail_to_change_metadata('version', '0.0', 400, "Field 'metadata.version' invalid")
          should_fail_to_change_metadata('version', 'not a version', 400, "Field 'metadata.version' invalid")
          should_fail_to_change_metadata('version', :delete, 400, "Field 'metadata.version' missing")
          should_fail_to_change_metadata('version', 1, 400, "Field 'metadata.version' invalid")
        end
      end # context for version

      context "for maintainer" do
        should_change_metadata('maintainer', 'Captain Stupendous')
        should_change_metadata('maintainer', :delete)
        if (ruby?)
          should_change_metadata('maintainer', true)
        else
          should_fail_to_change_metadata('maintainer', true, 400, "Field 'metadata.maintainer' invalid")
        end

        should_change_metadata('maintainer_email', 'cap@awesome.com')
        should_change_metadata('maintainer_email', 'not really an email')
        should_change_metadata('maintainer_email', :delete)
        if (ruby?)
          should_change_metadata('maintainer_email', false)
        else
          should_fail_to_change_metadata('maintainer_email', false, 400, "Field 'metadata.maintainer_email' invalid")
        end
      end # context for maintainer

      context "for license" do
        should_change_metadata('license', 'to_kill')
        should_change_metadata('license', :delete)
        if (ruby?)
          should_change_metadata('license', 1)
        else
          should_fail_to_change_metadata('license', 1, 400, "Field 'metadata.license' invalid")
        end
      end # context for license

      context "for collections" do
        ['platforms', 'providing'].each do |type|
          context "for #{type}" do
            json_error = "Field 'metadata.#{type}' invalid"
            if (ruby?)
              should_change_metadata(type, [])
            else
              should_fail_to_change_metadata(type, [], 400, json_error)
            end
            should_change_metadata(type, {})
            should_change_metadata(type, :delete)
            if (ruby?)
              should_change_metadata(type, "foo")
              should_change_metadata(type, ["foo"])
              should_change_metadata(type, {"foo" => {}})
            else
              should_fail_to_change_metadata(type, "foo", 400, json_error)
              should_fail_to_change_metadata(type, ["foo"], 400, json_error)
              should_fail_to_change_metadata(type, {"foo" => {}}, 400, "Invalid value '{[]}' for metadata.#{type}")
            end
          end # context for #{type}
        end # [loop over platforms, providing]

        context "for groupings" do
          json_error = "Field 'metadata.groupings' invalid"
          if (ruby?)
            should_change_metadata('groupings', [])
          else
            should_fail_to_change_metadata('groupings', [], 400, json_error)
          end
          should_change_metadata('groupings', {})
          should_change_metadata('groupings', :delete)
          if (ruby?)
            should_change_metadata('groupings', "foo")
            should_change_metadata('groupings', ["foo"])
          else
            should_fail_to_change_metadata('groupings', "foo", 400, json_error)
            should_fail_to_change_metadata('groupings', ["foo"], 400, json_error)
          end
          should_change_metadata('groupings', {"foo" => {}})
        end # context for groupings

        ['dependencies', 'recommendations', 'suggestions', 'conflicting',
         'replacing'].each do |type|
          context "for #{type}" do
            json_error = "Field 'metadata.#{type}' invalid"
            if (ruby?)
              should_change_metadata(type, [])
            else
              should_fail_to_change_metadata(type, [], 400, json_error)
            end
            should_change_metadata(type, {})
            should_change_metadata(type, :delete)
            if (ruby?)
              update_metadata_should_crash_server(type, "foo")
              should_not_change_metadata(type, ["foo"], {"foo" => []})
              should_change_metadata(type, {"foo" => {}})
            else
              should_fail_to_change_metadata(type, "foo", 400, json_error)
              should_fail_to_change_metadata(type, ["foo"], 400, json_error)
              should_fail_to_change_metadata(type, {"foo" => {}}, 400, "Invalid value '{[]}' for metadata.#{type}")
            end
          end # context for #{type}
        end # [loop over dependencies, recommendations, suggestions,
            #            conflicting, replacing]
      end # context for collections
    end # context when modifying metadata
  end # context PUT /cookbooks/<name>/<version> [update]
end
