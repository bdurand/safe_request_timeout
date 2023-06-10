# frozen_string_literal: true

module RequestTimeout
  class ActiveRecordHook
    class << self
      # Add the timeout hook to the connection class.
      #
      # @param connection_class [Class] The class to add the timeout hook to.
      # @return [void]
      def add_timeout!(connection_class = nil)
        connection_class ||= ::ActiveRecord::Base.connection.class

        RequestTimeout::Hooks.add_timeout!(connection_class, [:exec_query])

        RequestTimeout::Hooks.clear_timeout!(connection_class, [:commit_db_transaction])
      end
    end
  end
end
