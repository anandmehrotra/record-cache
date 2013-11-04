# @see http://outofti.me/post/4777884779/test-after-commit-hooks-with-transactional-fixtures
module ActiveRecord
  module ConnectionAdapters
    module DatabaseStatements
      #
      # Run the normal transaction method; when it's done, check to see if there
      # is exactly one open transaction. If so, that's the transactional
      # fixtures transaction; from the model's standpoint, the completed
      # transaction is the real deal. Send commit callbacks to models.
      #
      # If the transaction block raises a Rollback, we need to know, so we don't
      # call the commit hooks. Other exceptions don't need to be explicitly
      # accounted for since they will raise uncaught through this method and
      # prevent the code after the hook from running.
      #
      def transaction_with_transactional_fixtures(options = {}, &block)
        rolled_back = false

        transaction_without_transactional_fixtures do
          begin
            yield
          rescue Exception => exception
            if exception.is_a?(ActiveRecord::Rollback)
              rolled_back = true
            else
              puts "Exception in aftercommit: #{exception}"
              puts exception.backtrace
            end
            raise exception
          end
        end

        if !rolled_back && open_transactions == 1
          commit_transaction_records(false)
        end
      end
      alias_method_chain :transaction, :transactional_fixtures

      #
      # The @_current_transaction_records is an stack of arrays, each one
      # containing the records associated with the corresponding transaction
      # in the transaction stack. This is used by the
      # `rollback_transaction_records` method (to only send a rollback hook to
      # models attached to the transaction being rolled back) but is usually
      # ignored by the `commit_transaction_records` method. Here we
      # monkey-patch it to temporarily replace the array with only the records
      # for the top-of-stack transaction, so the real
      # `commit_transaction_records` method only sends callbacks to those.
      #
      def commit_transaction_with_transactional_fixtures(commit = true)
        unless commit
          real_current_transaction_records = @_current_transaction_records
          @_current_transaction_records = @_current_transaction_records.pop
        end

        begin
          @_current_transaction_records ||= []
          commit_transaction_records_without_transactional_fixtures
        rescue Exception => exception
          puts "Error in aftercommit: #{exception}"
          puts exception.backtrace
        ensure
          unless commit
            @_current_transaction_records = real_current_transaction_records
          end
        end
      end
      alias_method_chain :commit_transaction, :transactional_fixtures
    end
  end
end