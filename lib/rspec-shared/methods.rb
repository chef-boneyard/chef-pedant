# RSpecShared, written by Justin Ko <jko170@gmail.com>
# Original at https://github.com/justinko/rspec-shared

module RSpecShared
  module Methods
    def shared(name, &block)
      # Set these values up to be captured and shared
      value_defined = false
      value = nil
      let(name) do
        if !value_defined
          value = instance_eval(&block)
          value_defined
        end
        value
      end
    end
  end
end
