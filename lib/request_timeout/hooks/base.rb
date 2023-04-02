# frozen_string_literal: true

module RequestTimeout
  module Hooks
    # Base class for describing how to inject the time hooks code into another class.
    # This class should be extended and the subclass should set the klass, name, and methods
    # attributes in the constructor.
    class Base
      # The class that should be hooksed into.
      attr_accessor :klass

      # List of instance methods to hooks into.
      attr_accessor :methods

      # Inject timeout code into the specified class' methods.
      def add_timeout!
        raise ArgumentError.new("klass not specified") unless klass
        raise ArgumentError.new("methods not specified") if Array(methods).empty?
        module_name = "#{self.class.name.split("::").last}Hooks"
        Hooks.add_timeout!(klass, methods, module_name)
      end

      # Determine if the hook definition is valid.
      def valid?
        return false if klass.nil?
        all_methods = klass.public_instance_methods + klass.protected_instance_methods + klass.private_instance_methods
        Array(methods).all? { |m| all_methods.include?(m) }
      end
    end
  end
end
