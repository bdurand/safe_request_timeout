# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class ActiveRecord < Base
      def initialize
        @klass = ::ActiveRecord::Base.connection.class if defined?(::ActiveRecord::Base)
        @methods = [:exec_query]
      end
    end
  end
end
