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

# Utility methods for manipulating Pedant test gems.
module Pedant
  class Gem
    class << self
      # Return an array of names of all gems that contain Pedant test
      # specs.  Currently, this amounts to all gems whose name fits the
      # pattern 'opscode-pedant-PLATFORM_TYPE-tests'
      def names
        @names ||= ::Gem::Specification.map(&:name).grep(/-pedant-tests$/)
      end

      # Returns an array of absolute paths to Pedant test gems
      def base_directories
        @base_dirs ||= names.map { |name| ::Gem::Specification.find_by_name(name).gem_dir }
      end

      def absolute_paths_for(relative_path)
        base_directories.map { |dir| dir + relative_path }
      end

      # Returns an array of absolute paths to spec directories in Pedant test gems
      def test_directories
        @test_dirs ||= absolute_paths_for('/spec')
      end

      # Returns an array of absolute paths to fixtures directories in Pedant test gems
      def fixture_directories
        @fixture_dirs ||= absolute_paths_for('/fixtures')
      end
    end
  end
end
