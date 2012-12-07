module Caching
  class FileCache
      # create a private instance of MemoryStore
      def initialize
        @file_store = ActiveSupport::Cache::FileStore.new('/tmp/cache')
      end

      # this will allow our MemoryCache to be called just like Rails.cache
      # every method passed to it will be passed to our MemoryStore
      def method_missing(m, *args, &block)
        @file_store.send(m, *args)
      end

      # create the singleton object
      @@me = FileCache.new


      # this is a class method, we will be using it as follows: FileCache.instance
      def self.instance
        return @@me
      end

      # do not allow outsider calls to instantiate this cache
      private_class_method :new
  end
end