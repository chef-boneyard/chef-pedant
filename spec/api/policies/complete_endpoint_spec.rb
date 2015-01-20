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

# TODO: no focus
describe "Policies API endpoint", :policies, :focus do

  def mutate_json(data)
    parsed = parse(data)
    yield parsed
    to_json(parsed)
  end

  # Just until we rename the requestors
  let(:admin_requestor){ admin_user }

  let(:requestor){admin_requestor}

  let(:policies_url) { api_url("/policies") }

  let(:static_named_policy_url) { api_url("/policies/some_policy_group/some_policy_name") }

  let(:request_url) { static_named_policy_url }

  let(:minimum_valid_policy_payload) do
    <<-PAYLOAD
      {
        "name": "some_policy_name",
        "run_list": [
          "recipe[policyfile_demo::default]"
        ],
        "cookbook_locks": {
          "policyfile_demo": {
            "identifier": "f04cc40faf628253fe7d9566d66a1733fb1afbe9",
            "dotted_decimal_identifier": "67638399371010690.23642238397896298.25512023620585"
          }
        }
      }
    PAYLOAD
  end

  let(:canonical_policy_payload) do
    <<-PAYLOAD
      {
        "name": "some_policy_name",
        "run_list": [
          "recipe[policyfile_demo::default]"
        ],
        "named_run_lists": {
          "update_jenkins": [
            "recipe[policyfile_demo::other_recipe]"
          ]
        },
        "cookbook_locks": {
          "policyfile_demo": {
            "version": "0.1.0",
            "identifier": "f04cc40faf628253fe7d9566d66a1733fb1afbe9",
            "dotted_decimal_identifier": "67638399371010690.23642238397896298.25512023620585",
            "source": "cookbooks/policyfile_demo",
            "cache_key": null,
            "scm_info": {
              "scm": "git",
              "remote": "git@github.com:danielsdeleo/policyfile-jenkins-demo.git",
              "revision": "edd40c30c4e0ebb3658abde4620597597d2e9c17",
              "working_tree_clean": false,
              "published": false,
              "synchronized_remote_branches": [

              ]
            },
            "source_options": {
              "path": "cookbooks/policyfile_demo"
            }
          }
        },
        "solution_dependencies": {
          "Policyfile": [
            [ "policyfile_demo", ">= 0.0.0" ]
          ],
          "dependencies": {
            "policyfile_demo (0.1.0)": []
          }
        }
      }
    PAYLOAD
  end

  # TODO: remove hack
  let(:request_payload) { raise "define payload" }

  context "when no policies exist on the server" do

    context "GET" do

      let(:request_payload) { nil }

      let(:request_method) { :GET }

      it "GET /policies/:group/:name returns 404" do
        expect(response.code).to eq(404)
      end

    end

    context "DELETE" do

      let(:request_payload) { nil }

      let(:request_method) { :DELETE }

      it "DELETE /policies/:group/:name returns 404" do
        expect(response.code).to eq(404)
      end

    end

    context "PUT" do

      let(:request_method) { :PUT }

      after(:each) do
        delete(static_named_policy_url, requestor)
      end

      context "with a canonical payload" do

        let(:request_payload) { canonical_policy_payload }

        it "PUT /policies/:group/:name returns 201" do
          expect(response.code).to eq(201)
        end


      end

      context "with a minimal payload" do

        let(:request_payload) { minimum_valid_policy_payload }

        it "PUT /policies/:group/:name returns 201" do
          expect(response.code).to eq(201)
        end

      end

      context "when the request body is invalid" do

        ## MANDATORY FIELDS AND FORMATS
        # * `name`: String, other validation?
        # * `run_list`: Array
        # * `run_list[i]`: Fully Qualified Recipe Run List Item
        # * `cookbook_locks`: JSON Object
        # * `cookbook_locks(key)`: CookbookName
        # * `cookbook_locks[item]`: JSON Object, mandatory keys: "identifier", "dotted_decimal_identifier"
        # * `cookbook_locks[item]["identifier"]`: varchar(255) ?
        # * `cookbook_locks[item]["dotted_decimal_identifier"]` ChefCompatibleVersionNumber

        context "because of missing name field" do

          let(:request_payload) do
            mutate_json(minimum_valid_policy_payload) { |p| p.delete("name") }
          end

          it "PUT /policies/:group/:name returns 400" do
            expect(response.code).to eq(400)
            # TODO: message?
          end

        end

        context "because of an mismatched name field" do

          let(:request_payload) do
            mutate_json(minimum_valid_policy_payload) { |p| p["name"] = "monkeypants" }
          end

          it "PUT /policies/:group/:name returns 400" do
            expect(response.code).to eq(400)
          end

        end

        # TODO: invalid names (what are they?)
        # :( cookbook create spec does not exercise name validation.

        context "because of missing run_list field" do

          let(:request_payload) do
            mutate_json(minimum_valid_policy_payload) { |p| p.delete("run_list") }
          end

          it "PUT /policies/:group/:name returns 400" do
            expect(response.code).to eq(400)
            # TODO: message?
          end

        end

        context "because run_list field is the wrong type" do

          let(:request_payload) do
            mutate_json(minimum_valid_policy_payload) { |p| p["run_list"] = {} }
          end

          it "PUT /policies/:group/:name returns 400" do
            expect(response.code).to eq(400)
            # TODO: message?
          end

        end

        # TODO: invalid run list items
        # Roles endpoint tests run list items `123` (Int) and "recipe[" (Malformed run list item String)

        context "because cookbook_locks field is missing" do

          let(:request_payload) do
            mutate_json(minimum_valid_policy_payload) { |p| p.delete("cookbook_locks") }
          end

          it "PUT /policies/:group/:name returns 400" do
            expect(response.code).to eq(400)
            # TODO: message?
          end

        end

        context "because cookbook_locks field is the wrong type" do

          let(:request_payload) do
            mutate_json(minimum_valid_policy_payload) { |p| p["cookbook_locks"] = [] }
          end

          it "PUT /policies/:group/:name returns 400" do
            expect(response.code).to eq(400)
            # TODO: message?
          end

        end

        context "because cookbook_locks contains an entry of the wrong type" do

          let(:request_payload) do
            mutate_json(minimum_valid_policy_payload) { |p| p["cookbook_locks"]["invalid_member"] = [] }
          end

          it "PUT /policies/:group/:name returns 400" do
            expect(response.code).to eq(400)
            # TODO: message?
          end

        end

        context "because cookbook_locks contains an entry that is missing the identifier field" do

          let(:request_payload) do
            mutate_json(minimum_valid_policy_payload) do |policy|
              policy["cookbook_locks"]["invalid_member"] = { "dotted_decimal_identifier" => "1.2.3" }
            end
          end

          it "PUT /policies/:group/:name returns 400" do
            expect(response.code).to eq(400)
            # TODO: message?
          end

        end

        # TODO: what is validation on identifier? Max size?

        context "because cookbook_locks contains an entry that is missing the dotted_decimal_identifier field" do

          let(:request_payload) do
            mutate_json(minimum_valid_policy_payload) do |policy|
              policy["cookbook_locks"]["invalid_member"] = { "identifier" => "123def" }
            end
          end

          it "PUT /policies/:group/:name returns 400" do
            expect(response.code).to eq(400)
            # TODO: message?
          end

        end

        # TODO: dotted_decimal_identifier should validate the same as cookbook version numbers

      end

    end

  end

  context "when a policy exists on the server" do

    before(:each) do
      put(static_named_policy_url, requestor, payload: canonical_policy_payload)
    end

    context "GET" do

      let(:request_method) { :GET }

      let(:request_payload) { nil }

      it "retrieves the policy document" do
        expect(response.body).to eq(canonical_policy_payload)
      end

    end

    context "PUT (update policy document)" do

      let(:updated_canonical_policy_payload) do
        mutate_json(canonical_policy_payload) do |policy|
          policy["cookbook_locks"]["policyfile_demo"]["identifier"] = "2a42abea88dc847bf6d3194af8bf899908642421"
          policy["cookbook_locks"]["policyfile_demo"]["dotted_decimal_identifier"] = "11895255163526276.34892808658286783.151290363782177"
        end
      end

      let(:request_payload) { updated_canonical_policy_payload }

      let(:request_method) { :PUT }

      before(:each) do
        # Force the update PUT to occur
        response
      end

      it "PUT /policies/:group/:name returns 200" do
        expect(response.code).to eq(200)
        expect(response.body).to eq(updated_canonical_policy_payload)
      end

      it "GET /policies/:group/:name subsequently returns the updated document" do
        retrieved_doc = get(static_named_policy_url, requestor)
        expect(retrieved_doc.code).to eq(200)
        expect(retrieved_doc.body).to eq(updated_canonical_policy_payload)
      end
    end

    context "DELETE" do

      let(:request_payload) { nil }

      let(:request_method) { :DELETE }

      before(:each) do
        # Force the DELETE to occur
        response
      end


      it "DELETE /policies/:group/:name returns the deleted document" do
        expect(response.code).to eq(200)
        expect(response.body).to eq(canonical_policy_payload)
      end

      it "DELETE /policies/:group/:name removes the policy from the data store" do
        subsequent_get = get(static_named_policy_url, requestor)
        expect(subsequent_get.code).to eq(404)
      end


    end

  end

end

