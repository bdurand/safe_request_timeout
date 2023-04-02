# frozen_string_literal: true

module RequestTimeout
  module Hooks
    class ActiveRecord < Base
      def initialize
        @klass = ::ActiveRecord::Base.connection.class if defined?(::ActiveRecord::Base)
        @name = :database
        @methods = [:exec_query]
      end
    end
  end
end
