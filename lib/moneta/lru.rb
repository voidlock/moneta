require "delegate"

store = Moneta::LRU.new(Moneta::LMC.new) do
  include Moneta::LRU::LMCPolicy
end



class LRU < SimpleDelegator
  module MaxItemsPolicy
    attr_accessor :max_items
    attr_reader :size

    def initialize(store, options = {})
      @max_items = options.delete[:max_items]
      super
      @size = counting_walk
    end

    def []=(key, item)
      delete(tail_key) if size >= max_items
      item = super
      @size += 1
      item
    end

    def store(key, value, options = {})
      delete(tail_key) if size >= max_items
      item = super
      @size += 1
      item
    end

    private
    def counting_walk
      count = 0
      current = head_key
      while (current = next_key(current)) != TAIL_KEY
        count += 1
      end
      count
    end
  end

  module ExceptionPolicy
    def []=(key, item)
      begin
        super
      rescue
        handle_insert_exception($!)
        retry
      end
    end

    def store(key, value, options = {})
      begin
        super
      rescue
        delete(tail_key) if check_policy?
        retry
      end
    end

  end

  module Implementation

    # head and tail sentinels
    HEAD_KEY = "__!_HEAD_KEY_!__"
    TAIL_KEY = "__!_TAIL_KEY_!__"

    def initialize(store, options = {})
      super(store)
      ensure_sentinels
    end

    # Delete an item from the cache.
    def delete(key)
      lru_delete(key) if item = super
      item
    end

    # Lookup an item in the cache.
    def [](key)
      lru_touch(key) if item = super
      item
    end

    # The inserted item is considered mru!
    def []=(key, item)
      begin
        lru_insert(key)
        super
      rescue
        handle_insert_exception($!)
        retry
      end
    end

    def store(key, value, options = {})
      begin
        lru_insert(key)
        super
      rescue
        handle_insert_exception($!)
        retry
      end
    end

    # The first item (MRU).
    def first
      lru_get(lru_get(TAIL_KEY))
    end

    # The last item (LRU)
    def last
      lru_get(lru_get(TAIL_KEY))
    end

    # The key of the head item (MRU).
    def head_key
      lru_get(HEAD_KEY)
    end

    # The key of the tail item (LRU).
    def tail_key
      lru_get(TAIL_KEY)
    end

    # Given a key returns the key of previous item.
    def prev_key(key)
      lru_get(lru_prev_key(key))
    end

    # Given a key returns the key of next item.
    def next_key(key)
      lru_get(lru_next_key(key))
    end

    private

    def lru_prev_key(key)
      case key
      when HEAD_KEY
        HEAD_KEY
      when TAIL_KEY
        TAIL_KEY
      else
        "#{key}__!_PREV_KEY_!__"
      end
    end

    def lru_next_key(key)
      case key
      when HEAD_KEY
        HEAD_KEY
      when TAIL_KEY
        TAIL_KEY
      else
        "#{key}__!_NEXT_KEY_!__"
      end
    end

    # gets item without affecting lru
    def lru_get(key)
      __getobj__[key]
    end

    # sets item without affecting lru
    def lru_set(key, value)
      __getobj__[key] = value
    end

    def lru_append(parent_key, child_key)
      lru_join(child_key, lru_next(parent_key))
      lru_join(parent_key, child_key)
    end

    def lru_insert(key)
      lru_append(HEAD_KEY, key)
    end

    def lru_join(prev_key, next_key)
      lru_set(lru_prev_key(next_key), prev_key)
      lru_set(lru_next_key(prev_key), next_key)
    end

    def lru_touch(key)
      lru_append(HEAD_KEY, lru_delete(key))
    end

    def lru_delete(key)
      lru_join(prev_key(key), next_key(key))

      # cleanup the linked list keys
      __getobj__.delete(lru_prev_key(key))
      __getobj__.delete(lru_next_key(key))

      # return the key
      return key
    end

    def ensure_sentinels
      unless lru_get(HEAD_KEY) && lru_get(TAIL_KEY)
        lru_set(HEAD_KEY, TAIL_KEY)
        lru_set(TAIL_KEY, HEAD_KEY)
      end
    end
  end
  include Implementation
end
