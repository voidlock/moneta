module Moneta
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
    
    def fetch(key, default = nil, &blk)
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
      update_options(key, options)
      super(key, value)
    end
    
    private
    def update_options(key, options)
      if options[:expires_in]
        @expiration[key] = (Time.now + options[:expires_in])
      end
    end
  end
end