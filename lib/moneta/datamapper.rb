begin
  gem "dm-core", "0.9.10"
  require "dm-core"
rescue LoadError
  puts "You need the dm-core gem in order to use the DataMapper moneta store"
  exit
end

class MonetaHash
  include DataMapper::Resource

  property :the_key, String, :key => true
  property :value, Object, :lazy => false
  property :expires, Time

  def self.value(key)
    obj = self.get(key)
    obj && obj.value
  end
end

module Moneta
  class DataMapper
    class Expiration
      def initialize(klass, repository)
        @klass = klass
        @repository = repository
      end

      def [](key)
        if obj = get(key)
          obj.expires
        end
      end

      def []=(key, value)
        obj = get(key)
        obj.expires = value
        obj.save(@repository)
      end

      def delete(key)
        obj = get(key)
        obj.expires = nil
        obj.save(@repository)
      end

      private
      def get(key)
        DataMapper.repository(@repository) { @klass.get(key) }
      end
    end

    def initialize(options = {})
      @repository = options.delete(:repository) || :moneta
      ::DataMapper.setup(@repository, options[:setup])
      repository_context { MonetaHash.auto_upgrade! }
      @hash = MonetaHash
      @expiration = Expiration.new(MonetaHash, @repository)
    end

    module Implementation
      def fetch(key, *args)
        repository_context {
          obj = @hash.get(key)
          if obj
            obj = obj.value
          end
          obj
        }
      end

      def delete(key)
        repository_context { @hash.all(:the_key => key).destroy! }
      end

      def store(key, value, options = {})
        repository_context {
          obj = @hash.get(key)
          if obj
            obj.update(key, value)
            obj
          else
            @hash.create(:the_key => key, :value => value)
          end
        }
      end

      def clear
        repository_context { @hash.all.destroy! }
      end

      private
      def repository_context
        DataMapper.repository(@repository) { yield }
      end
    end
    include Implementation
    include BaseImplementation
    include Expires
  end
end