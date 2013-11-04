require 'active_record'

# basic Record Cache functionality
ActiveRecord::Base.send(:include, RecordCache::Base)

# To be able to fetch records from the cache and invalidate records in the cache
# some internal Active Record methods needs to be aliased.
# The downside of using internal methods, is that they may change in different releases,
# hence the following code:
AR_VERSION = 31

if ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 0
	AR_VERSION = 30
elsif ActiveRecord::VERSION::MAJOR == 3 && ActiveRecord::VERSION::MINOR == 1
	AR_VERSION = 31	
elsif ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR == 0
	AR_VERSION = 40
end

require File.dirname(__FILE__) + "/active_record_#{AR_VERSION}.rb"
