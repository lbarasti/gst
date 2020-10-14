require "agent"

class ConcurrentHash(K, V)
  def initialize
    @hash = Agent(Hash(K,V)).new(Hash(K,V).new)
  end

  def [](key) : V
    @hash.get! { |h| h[key]}
  end

  def []?(key) : V?
    @hash.get! { |h| h[key]?}
  end

  def []=(key, value)
    @hash.update { |h|
      h[key] = value
      h
    }
  end

  def size : Int32
    @hash.get!(&.size)
  end

  def delete(key)
    @hash.update { |h|
      h.delete(key)
      h
    }
  end
end