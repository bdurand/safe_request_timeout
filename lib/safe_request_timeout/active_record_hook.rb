# frozen_string_literal: true

module SafeRequestTimeout
  class ActiveRecordHook
    class << self
      # Add the timeout hook to the connection class.
      #
      # @param connection_class [Class] The class to add the timeout hook to.
      # @return [void]
      def add_timeout!(connection_class = nil)
        connection_class ||= ::ActiveRecord::Base.connection.class
        exec_method = (connection_class.instance_methods.include?(:internal_exec_query) ? :internal_exec_query : :exec_query)

        SafeRequestTimeout::Hooks.add_timeout!(connection_class, [exec_method])

        SafeRequestTimeout::Hooks.clear_timeout!(connection_class, [:commit_db_transaction])
      end
    end
  end
end
