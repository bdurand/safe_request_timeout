# frozen_string_literal: true

module SafeRequestTimeout
  # Hooks into other classes from other libraries with timeout blocks. This allows
  # timeouts to be automatically checked before making requests to external services.
  module Hooks
    class << self
      # Hooks into a class by surrounding specified instance methods with timeout checks.
      def add_timeout!(klass, methods, module_name = nil)
        hooks_module = create_module(klass, module_name, "AddTimeout")

        Array(methods).each do |method_name|
          hooks_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method_name}(#{splat_args})
              SafeRequestTimeout.check_timeout!
              super(#{splat_args})
            end
          RUBY
        end

        klass.prepend(hooks_module)
      end

      def clear_timeout!(klass, methods, module_name = nil)
        hooks_module = create_module(klass, module_name, "ClearTimeout")

        Array(methods).each do |method_name|
          hooks_module.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method_name}(#{splat_args})
              SafeRequestTimeout.clear_timeout
              super(#{splat_args})
            end
          RUBY
        end

        klass.prepend(hooks_module)
      end

      private

      def create_module(klass, module_name, module_type)
        # Create a module that will be prepended to the specified class.
        unless module_name
          camelized_name = name.to_s.gsub(/[^a-z0-9]+([a-z0-9])/i) { |m| m[m.length - 1, m.length].upcase }
          camelized_name = "#{camelized_name[0].upcase}#{camelized_name[1, camelized_name.length]}"
          module_name = "#{klass.name.split("::").join}#{camelized_name}#{module_type}"
        end

        if const_defined?(module_name)
          raise ArgumentError.new("Cannot create duplicate #{module_name} for hooking #{name} into #{klass.name}")
        end

        # Dark arts & witchery to dynamically generate the module methods.
        const_set(module_name, Module.new)
      end

      def splat_args
        # The method of overriding kwargs changed in ruby 2.7
        ruby_major, ruby_minor, _ = RUBY_VERSION.split(".").collect(&:to_i)
        ruby_3_args = (ruby_major >= 3 || (ruby_major == 2 && ruby_minor >= 7))
        (ruby_3_args ? "..." : "*args, &block")
      end
    end
  end
end
