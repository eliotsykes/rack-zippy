module Rack
  module Zippy
    module Configuration
      def configure
        yield self
      end

      def define_setting(name, default = nil)
        default_copy = begin
                         default.dup
        rescue TypeError
                         default
        end
        class_variable_set("@@#{name}", default_copy)

        define_class_method "#{name}=" do |value|
          class_variable_set("@@#{name}", value)
        end
        define_class_method name do
          class_variable_get("@@#{name}")
        end
        define_class_method "reset_#{name}" do
          class_variable_set("@@#{name}", default)
        end
      end

      private

      def define_class_method(name, &block)
        (class << self; self; end).instance_eval do
          define_method name, &block
        end
      end

    end
  end
end
