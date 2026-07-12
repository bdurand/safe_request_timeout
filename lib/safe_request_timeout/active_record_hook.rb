# frozen_string_literal: true

module SafeRequestTimeout
  class ActiveRecordHook
    MUTEX = Mutex.new
    private_constant :MUTEX

    @hooked_classes = []

    class << self
      # Add the timeout hook to a connection adapter class. If no class is given, then the
      # hooks will be added to each connection adapter class the first time it is instantiated.
      # This does not require a database connection to be established and covers every adapter
      # in use, including applications with multiple databases.
      #
      # @param connection_class [Class] The class to add the timeout hook to.
      # @return [void]
      def add_timeout!(connection_class = nil)
        if connection_class
          add_hooks(connection_class)
        else
          ::ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(AdapterInitializer)
          # Add the hooks to any adapter that already has a live connection.
          if ::ActiveRecord::Base.connected?
            ::ActiveRecord::Base.connection_pool.with_connection do |connection|
              add_hooks(connection.class)
            end
          end
        end
      end

      private

      def add_hooks(connection_class)
        MUTEX.synchronize do
          return if @hooked_classes.include?(connection_class)

          exec_method = (connection_class.method_defined?(:internal_exec_query) ? :internal_exec_query : :exec_query)
          SafeRequestTimeout::Hooks.add_timeout!(connection_class, [exec_method])
          SafeRequestTimeout::Hooks.clear_timeout!(connection_class, [:commit_db_transaction])

          @hooked_classes << connection_class
        end
      end
    end

    # Prepended to AbstractAdapter so the timeout hooks are added to each concrete adapter
    # class the first time it is instantiated. The hooks must go on the concrete class since
    # adapters can override the hooked methods.
    module AdapterInitializer
      ruby_major, ruby_minor, _ = RUBY_VERSION.split(".").collect(&:to_i)
      splat_args = ((ruby_major >= 3 || (ruby_major == 2 && ruby_minor >= 7)) ? "..." : "*args, &block")
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def initialize(#{splat_args})
          super(#{splat_args})
          SafeRequestTimeout::ActiveRecordHook.add_timeout!(self.class)
        end
      RUBY
    end
  end
end
