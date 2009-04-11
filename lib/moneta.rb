module Moneta
  module BaseImplementation
    attr_writer :default

    def key?(key)
      !self.fetch(key, nil).nil?
    end

    alias :has_key? :key?

    def [](key)
      fetch(key, default(key))
    end

    def []=(key, value)
      store(key, value)
    end

    def fetch(key, *args)
      value = super
      value ||= args[0] if args.any?
      value ||= yield(key) if block_given?
      raise IndexError, "key not found" if value.nil? && args.empty? && !block_given?
      value
    end

    def update_key(key, options = {})
      val = self.fetch(key)
      self.store(key, val, options)
    end

    def delete(key)
      value = self[key]
      super(key) if value
      value
    end

    def default(key = nil)
      @default
    end
  end
  module Expires
    def check_expired(key)
      if @expiration[key] && Time.now > @expiration[key]
        @expiration.delete(key)
        self.delete(key)
      end
    end
    
    def key?(key)
      check_expired(key)
      super
    end
    
    def [](key)
      check_expired(key)
      super
    end
    
    def fetch(key, *args)
      check_expired(key)
      super
    end
    
    def delete(key)
      check_expired(key)
      super
    end
        
    def update_key(key, options)
      update_options(key, options)      
    end
    
    def store(key, value, options = {})
      super(key, value)
      update_options(key, options)
    end
    
    private
    def update_options(key, options)
      if options[:expires_in]
        @expiration[key] = (Time.now + options[:expires_in])
      end
    end
  end
end