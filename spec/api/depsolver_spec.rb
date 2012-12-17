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
require 'pedant/rspec/environment_util'

describe "Depsolver API endpoint", :depsolver do
  include Pedant::RSpec::CookbookUtil
  include Pedant::RSpec::EnvironmentUtil

  def self.ruby?
    Pedant::Config.ruby_environment_endpoint?
  end

  # include_context "configuration_check"

  let(:env){ "test_depsolver_env"}
  let(:no_cookbooks_env) { "test_depsolver_no_cookbooks_env" }
  let(:cookbook_name){"foo"}
  let(:cookbook_version){"1.2.3"}
  let(:cookbook_name2) {"bar"}
  let(:cookbook_version2) {"2.0.0"}

  # We run all the depsolver tests in a newly created environment
  before(:all) {
    # Make sure we are testing an environment that has some
    # constraints even, if they don't actually constrain.
    the_env = new_environment(env)
    the_env['cookbook_versions'] = {
      'qux' => "> 4.0.0",
      'foo' => ">= 0.1.0",
      'bar' => "< 4.0.0"
    }
    add_environment(admin_user, the_env)

    no_cb_env = new_environment(no_cookbooks_env)
    no_cb_env['cookbook_versions'] = {
      'foo' => '= 400.0.0',
      'bar' => '> 400.0.0'
    }
    add_environment(admin_user, no_cb_env)
  }

  after(:all) {
    delete_environment(admin_user, env)
    delete_environment(admin_user, no_cookbooks_env)
  }

  context "POST /environments/:env/cookbook_versions" do

    context "empty and error cases" do
      before(:all) {
        make_cookbook(admin_user, cookbook_name, cookbook_version)
      }

      after(:all) {
        delete_cookbook(admin_user, cookbook_name, cookbook_version)
      }

      it "returns 400 with an empty payload", :validation do
        payload = ""
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
            :payload => payload) do |response|
          response.should look_like({
                                     :status => 400,
                                     :body_exact => {
                                         "error" =>
                                             if ruby?
                                                 ["Missing param: run_list"]
                                             else
                                                 ["invalid JSON"]
                                             end
                                     }
                                    })
        end
      end

      it "returns 400 with an non-json payload", :validation do
        payload = "this_is_not_json"
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
            :payload => payload) do |response|
          response.should look_like({
                                     :status => 400,
                                     :body_exact => {
                                         "error" =>
                                             if ruby?
                                                 ["Missing param: run_list"]
                                             else
                                                 ["invalid JSON"]
                                             end
                                     }
                                    })
        end
      end

      let(:environment_name){"not@environment"}




      if ruby?
        # Ruby endpoint doesn't really do the right thing... just
        # copying this over from an older Pedant incarnation
        it "returns (WRONGLY) 403 with an invalid environment" do
          payload = "{\"run_list\":[]}"
          post(api_url("/environments/not@environment/cookbook_versions"), admin_user,
               :payload => payload) do |response|
            response.should look_like({
                                        :status => 403,
                                        :body_exact => {
                                          "error" => ["Merb::ControllerExceptions::Forbidden"]
                                        }
                                      })
          end
        end
      else
        it "returns 404 with an invalid environment" do
          payload = "{\"run_list\":[]}"
          post(api_url("/environments/#{environment_name}/cookbook_versions"), normal_user,
             :payload => payload) do |response|
            response.should look_like environment_not_found_response
          end
        end
      end
      it "returns 400 with non-Array as run_list value", :validation do
        payload = "{\"run_list\":\"#{cookbook_name}\"}"
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
            :payload => payload) do |response|
          response.should look_like({
                                     :status => 400,
                                     :body_exact => {
                                         "error" =>
                                             if ruby?
                                                 ["Param run_list is not an Array: String"]
                                             else
                                                 ["Field 'run_list' is not a valid run list"]
                                             end
                                     }
                                    })
        end
      end

      if ruby?
        it "returns (WRONGLY) 400 (run_list missing) with malformed JSON" do
          payload = "{\"run_list\": "
          post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
              :payload => payload) do |response|
            response.should look_like({
                                       :status => 400,
                                       :body_exact => {
                                           "error" => ["Missing param: run_list"]
                                       }
                                      })
          end
        end
      else
        it "returns 400 with malformed JSON", :validation do
          payload = "{\"run_list\": "
          post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
              :payload => payload) do |response|
            response.should look_like({
                                       :status => 400,
                                         :body_exact => {
                                           "error" => ["invalid JSON"]
                                       }
                                      })
          end
        end
      end

      it "returns Error with an malformed item in run_list (int)", :validation do
        payload = "{\"run_list\": [12]}"
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
            :payload => payload) do |response|
          response.should look_like(if ruby? then
                                    {
                                     :status => 500,
                                     :body_exact => {
                                         "error" => ["Unable to create Chef::RunList::RunListItem from Fixnum:12: must be a Hash or String"]
                                     }
                                    }
                                    else
                                    {
                                     :status => 400,
                                     :body_exact => {
                                         "error" => ["Field 'run_list' is not a valid run list"]
                                     }
                                    }
                                    end
                                   )
        end
      end

      it "returns 200 with an empty run_list" do
        payload = "{\"run_list\":[]}"
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
            :payload => payload) do |response|
          response.should look_like({
                                     :status => 200,
                                     :body_exact => {
                                     }

                                    })
        end
      end

      it "returns 412 with a non-existent cookbook in _default environment" do
        not_exist = "this_does_not_exist"
        payload = "{\"run_list\":[\"#{not_exist}\"]}"
        error_message = "{\"message\":\"Run list contains invalid items: no such cookbook #{not_exist}.\","\
                        "\"non_existent_cookbooks\":[\"#{not_exist}\"],\"cookbooks_with_no_versions\":[]}"
        error_hash = {
          "message" => "Run list contains invalid items: no such cookbook #{not_exist}.",
          "non_existent_cookbooks" => [ not_exist ],
          "cookbooks_with_no_versions" => []
        }
        post(api_url("/environments/_default/cookbook_versions"), admin_user,
             :payload => payload) do |response|
        response.should look_like({
                                   :status => 412,
                                   :body_exact => {
                                       "error" => [if ruby? then error_message else error_hash end]
                                   }
                                  })
        end
      end

      it "returns 412 with a non-existent cookbook" do
        not_exist = "this_does_not_exist"
        payload = "{\"run_list\":[\"#{not_exist}\"]}"
        error_message = "{\"message\":\"Run list contains invalid items: no such cookbook #{not_exist}.\","\
                        "\"non_existent_cookbooks\":[\"#{not_exist}\"],\"cookbooks_with_no_versions\":[]}"
        error_hash = {
          "message" => "Run list contains invalid items: no such cookbook #{not_exist}.",
          "non_existent_cookbooks" => [ not_exist ],
          "cookbooks_with_no_versions" => []
        }
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
             :payload => payload) do |response|
        response.should look_like({
                                   :status => 412,
                                   :body_exact => {
                                       "error" => [if ruby? then error_message else error_hash end]
                                   }
                                  })
        end
      end

      it "returns 412 with an existing cookbook filtered out by environment" do
        payload = "{\"run_list\":[\"#{cookbook_name}\"]}"

        error_message = "{\"message\":\"Run list contains invalid items: no such cookbook #{cookbook_name}.\","\
                        "\"non_existent_cookbooks\":[\"#{cookbook_name}\"],\"cookbooks_with_no_versions\":[]}"
        error_hash = {
          "message" => "Unable to satisfy constraints on cookbook foo, which does not exist.",
          "non_existent_cookbooks" => ["foo"],
          "most_constrained_cookbooks"=>[]
        }
        post(api_url("/environments/#{no_cookbooks_env}/cookbook_versions"), admin_user,
             :payload => payload) do |response|
        response.should look_like({
                                   :status => 412,
                                   :body_exact => {
                                       "error" => [if ruby? then error_message else error_hash end]
                                   }
                                  })
        end
      end

      it "returns 412 and both cookbooks with more than one non-existent cookbook" do
        not_exist1 = "this_does_not_exist"
        not_exist2 = "also_this_one"
        payload = "{\"run_list\":[\"#{not_exist1}\", \"#{not_exist2}\"]}"
        error_message = "{\"message\":\"Run list contains invalid items: no such cookbooks #{not_exist1}, #{not_exist2}.\","\
                        "\"non_existent_cookbooks\":[\"#{not_exist1}\",\"#{not_exist2}\"],\"cookbooks_with_no_versions\":[]}"
        error_hash = {
          "message" => "Run list contains invalid items: no such cookbooks #{not_exist1}, #{not_exist2}.",
          "non_existent_cookbooks" => [ not_exist1, not_exist2 ],
          "cookbooks_with_no_versions" => []
        }

        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
             :payload => payload) do |response|
        response.should look_like({
                                   :status => 412,
                                   :body_exact => {
                                       "error" => [if ruby? then error_message else error_hash end]
                                   }
                                  })
        end
      end

      it "returns 412 when there is a runlist entry specifying version that doesn't exist" do
        missing_version_payload = "{\"run_list\":[\"#{cookbook_name}@#{cookbook_version2}\"]}"
        error_message = "{\"message\":\"Run list contains invalid items: no versions match the constraints on cookbook #{cookbook_name}.\","\
                        "\"non_existent_cookbooks\":[],\"cookbooks_with_no_versions\":[\"#{cookbook_name}\"]}"
        error_hash = {
          "message" => "Run list contains invalid items: no versions match the constraints on cookbook (#{cookbook_name} = #{cookbook_version2}).",
          "non_existent_cookbooks" => [],
          "cookbooks_with_no_versions" => ["(#{cookbook_name} = #{cookbook_version2})"]
        }
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
             :payload => missing_version_payload) do |response|
        response.should look_like({
                                   :status => 412,
                                   :body_exact => {
                                       "error" => [if ruby? then error_message else error_hash end]
                                   }
                                  })
        end
      end


      # TODO: See if it is possible to get both errors out for non-existent runlist items and
      # cookbooks which have no versions matching constraints
      it "returns 412 and both errors non-existent and no versions cookbooks" do
        not_exist = "this_does_not_exist"
        payload = "{\"run_list\":[\"#{not_exist}\", \"#{cookbook_name}@2.0.0\"]}"
        error_message = "{\"message\":\"Run list contains invalid items: no such cookbook #{not_exist};"\
          " no versions match the constraints on cookbook #{cookbook_name}.\","\
          "\"non_existent_cookbooks\":[\"#{not_exist}\"],\"cookbooks_with_no_versions\":[\"#{cookbook_name}\"]}"
        error_hash = {
          "message" => "Run list contains invalid items: no such cookbook #{not_exist}.",
          "non_existent_cookbooks" => [ not_exist ],
          "cookbooks_with_no_versions" => []
        }
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
             :payload => payload) do |response|
        response.should look_like({
                                   :status => 412,
                                   :body_exact => {
                                       "error" => [if ruby? then error_message else error_hash end]
                                   }
                                  })
        end
      end

    end # empty and error cases context

    context "dependency error cases (one cookbook)" do
      let(:payload) {"{\"run_list\":[\"#{cookbook_name}\"]}"}

      # We create the cookbook in the test with a specific dependency.
      # Clean it up here
      after(:each) {
        delete_cookbook(admin_user, cookbook_name, cookbook_version)
      }

      # TODO: need more detailed depsolver output to construct error message
      it "returns 412 when there is a dep that doesn't exist" do
        not_exist_name = "this_does_not_exist"
        opts = { :dependencies => {not_exist_name => ">= 0.0.0"}}
        make_cookbook(admin_user, cookbook_name, cookbook_version,opts)
        error_message =
          "{\"message\":\"Unable to satisfy constraints on cookbook #{not_exist_name}, "\
          "which does not exist, due to run list item (#{cookbook_name} >= 0.0.0). "\
           "Run list items that may result in a constraint on #{not_exist_name}: "\
           "[(#{cookbook_name} = #{cookbook_version}) -> (#{not_exist_name} >= 0.0.0)]\","\
           "\"unsatisfiable_run_list_item\":\"(#{cookbook_name} >= 0.0.0)\","\
           "\"non_existent_cookbooks\":[\"Package #{not_exist_name}\"],"\
           "\"most_constrained_cookbooks\":[]}"
        error_hash = {
          "message" => "Unable to satisfy constraints on cookbook #{not_exist_name}, which does not exist.",
          "non_existent_cookbooks" => [ not_exist_name ],
          "most_constrained_cookbooks" => []
        }
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
             :payload => payload) do |response|
        response.should look_like({
                                   :status => 412,
                                   :body_exact => {
                                       "error" => [if ruby? then error_message else error_hash end]
                                   }
                                  })
        end
      end
    end # dependency error cases (one cookbook)

    context "dependency error cases (two cookbooks)" do
      let(:payload) {"{\"run_list\":[\"#{cookbook_name}\"]}"}

      # We create the cookbooks in the test with a specific dependency.
      # Clean them up here
      after(:each) {
        delete_cookbook(admin_user, cookbook_name, cookbook_version)
        delete_cookbook(admin_user, cookbook_name2, cookbook_version2)
      }

      it "returns 412 and both entries when there are runlist entries specifying versions that don't exist" do
        make_cookbook(admin_user, cookbook_name, cookbook_version)
        make_cookbook(admin_user, cookbook_name2, cookbook_version2)
        missing_version_payload = "{\"run_list\":[\"#{cookbook_name2}@2.0.0\", \"#{cookbook_name}@3.0.0\"]}"
        error_message = "{\"message\":\"Run list contains invalid items: no versions match the constraints on cookbook #{cookbook_name}.\","\
                        "\"non_existent_cookbooks\":[],\"cookbooks_with_no_versions\":[\"#{cookbook_name}\"]}"
        error_hash = {
          "message" => "Run list contains invalid items: no versions match the constraints on cookbook (#{cookbook_name2} = 2.0.0),(#{cookbook_name} = 3.0.0).",
          "non_existent_cookbooks" => [],
          "cookbooks_with_no_versions" => ["(#{cookbook_name2} = 2.0.0)", "(#{cookbook_name} = 3.0.0)"]
        }
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
             :payload => missing_version_payload) do |response|
        response.should look_like({
                                   :status => 412,
                                   :body_exact => {
                                       "error" => [if ruby? then error_message else error_hash end]
                                   }
                                  })
        end
      end

      # TODO: need more detailed depsolver output to construct error message
      it "returns 412 when there is a dep that doesn't have new enough version" do
        opts = { :dependencies => {cookbook_name2 => "> #{cookbook_version2}"} }
        make_cookbook(admin_user, cookbook_name, cookbook_version, opts)
        make_cookbook(admin_user, cookbook_name2, cookbook_version2)
        error_message =
            "{\"message\":\"Unable to satisfy constraints on cookbook #{cookbook_name2} "\
            "due to run list item (#{cookbook_name} >= 0.0.0). "\
            "Run list items that may result in a constraint on #{cookbook_name2}: "\
            "[(#{cookbook_name} = #{cookbook_version}) -> (#{cookbook_name2} > #{cookbook_version2})]\","\
            "\"unsatisfiable_run_list_item\":\"(#{cookbook_name} >= 0.0.0)\","\
            "\"non_existent_cookbooks\":[],"\
            "\"most_constrained_cookbooks\":[\"Package #{cookbook_name2}\\n  2.0.0 -> []\"]}"
        error_hash = {
          "message" => "Unable to solve constraints, the following solutions were attempted \n\n"\
                       "    Unable to satisfy goal constraint #{cookbook_name} due to constraint on bar\n"\
                       "        (#{cookbook_name} = #{cookbook_version}) -> (#{cookbook_name2} > #{cookbook_version2})\n",
          "unsatisfiable_run_list_item" => [cookbook_name],
          "non_existent_cookbooks" => [],
          "most_constrained_cookbooks" => ["(#{cookbook_name2} > #{cookbook_version2})"]
        }
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
             :payload => payload) do |response|
        response.should look_like({
                                   :status => 412,
                                   :body_exact => {
                                       "error" => [if ruby? then error_message else error_hash end]
                                   }
                                  })
        end
      end

      # TODO: need more detailed depsolver output to construct error message
      it "returns 412 when there is an impossible dependency" do
        opts1 = { :dependencies => {cookbook_name2=>"> 2.0.0"}}
        opts2 = { :dependencies => {cookbook_name=>"> 3.0.0"}}
        make_cookbook(admin_user, cookbook_name, cookbook_version, opts1)
        make_cookbook(admin_user, cookbook_name2, cookbook_version2, opts2)
        error_message =
            "{\"message\":\"Unable to satisfy constraints on cookbook #{cookbook_name2} "\
            "due to run list item (#{cookbook_name} >= 0.0.0). "\
            "Run list items that may result in a constraint on #{cookbook_name2}: "\
            "[(#{cookbook_name} = #{cookbook_version}) -> (#{cookbook_name2} > #{cookbook_version2})]\","\
            "\"unsatisfiable_run_list_item\":\"(#{cookbook_name} >= 0.0.0)\","\
            "\"non_existent_cookbooks\":[],"\
            "\"most_constrained_cookbooks\":[\"Package #{cookbook_name2}\\n  2.0.0 -> [(#{cookbook_name} > 3.0.0)]\"]}"
        error_hash = {
          "message" => "Unable to solve constraints, the following solutions were attempted \n\n"\
                       "    Unable to satisfy goal constraint #{cookbook_name} due to constraint on bar\n"\
                       "        (#{cookbook_name} = #{cookbook_version}) -> (#{cookbook_name2} > #{cookbook_version2})\n",
          "unsatisfiable_run_list_item" => [cookbook_name],
          "non_existent_cookbooks" => [],
          "most_constrained_cookbooks" => ["(#{cookbook_name2} > #{cookbook_version2})"]
        }
        post(api_url("/environments/#{env}/cookbook_versions"), admin_user,
             :payload => payload) do |response|
        response.should look_like({
                                   :status => 412,
                                   :body_exact => {
                                       "error" => [if ruby? then error_message else error_hash end]
                                   }
                                  })
        end
      end

    end # dependency error cases (two cookbooks)

    context "success cases" do
      let(:payload) {"{\"run_list\":[\"#{cookbook_name}\"]}"}

      before(:all) {
        make_cookbook(admin_user, cookbook_name, cookbook_version)
      }

      after(:all) {
        delete_cookbook(admin_user, cookbook_name, cookbook_version)
      }

      it "returns 200 with a minimal good cookbook", :smoke do
        post(api_url("/environments/#{env}/cookbook_versions"), normal_user,
            :payload => payload) do |response|
          response.should look_like({
                                     :status => 200,
                                     :body_exact => {
                                         cookbook_name => minimal_cookbook(cookbook_name, cookbook_version)
                                     }
                                    })
        end
      end

      # TODO: Check with a cookbook that has some files in segments since we also get
      # back URLs
    end # success cases context
  end # global context
end # describe
