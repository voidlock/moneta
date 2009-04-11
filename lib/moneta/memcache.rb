begin
  require "memcache"
rescue LoadError
  puts "You need the memcache gem to use the Memcache moneta store"
  exit  
end

module Moneta  
  class Memcache
    module Implementation
      def initialize(options = {})
        @cache = MemCache.new(options.delete(:server), options)
      end

      def fetch(key, *args)
        @cache.get(key)
      end

      def delete(key)
        @cache.delete(key)
      end

      def store(key, value, options = {})
        args = [key, value, options[:expires_in]].compact
        @cache.set(*args)
      end

      def clear
        @cache.flush_all
      end
    end
    include Implementation
    include BaseImplementation
  end
end
