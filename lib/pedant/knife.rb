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

module Pedant
  module Knife
    # Convenience function for grabbing a hash of several important
    # Mixlib::Shellout command configuration parameters.
    def self.command_setting(shellout_command)
      keys = [:cwd, :user, :group, :umask, :timeout, :valid_exit_codes, :environment]
      keys.inject({}) do |hash, attr|
        hash[attr] = shellout_command.send(attr)
        hash
      end
    end

  end
end
