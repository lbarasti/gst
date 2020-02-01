class ConcurrentHash(K, V)
  record Write(K,V), key : K, value : V
  record Read(K,V), ch : Channel(V), key : K
  record ReadMaybe(K,V), ch : Channel(V?), key : K
  record Size, ch : Channel(Int32)
  record Delete(K), key : K

  @commands = Channel(Write(K,V) | ReadMaybe(K,V) | Read(K,V) | Size | Delete(K)).new
  def initialize
    hash = Hash(K,V).new
    spawn(name: "ConcurrentHash") do
      loop do
        case cmd = @commands.receive
        when Write
          hash[cmd.key] = cmd.value
        when ReadMaybe
          cmd.ch.send hash[cmd.key]?
        when Read
          cmd.ch.send hash[cmd.key]
        when Size
          cmd.ch.send hash.size
        when Delete
          hash.delete(cmd.key)
        end
      end
    end
  end

  def [](key) : V
    Channel(V).new(1).tap { |ch|
      @commands.send Read(K,V).new(ch, key)
    }.receive
  end

  def []?(key) : V?
    Channel(V?).new(1).tap { |ch|
      @commands.send ReadMaybe(K,V).new(ch, key)
    }.receive
  end

  def []=(key,value)
    @commands.send Write(K,V).new(key, value)
  end

  def size : Int32
    Channel(Int32).new(1).tap { |ch|
      @commands.send Size.new(ch)
    }.receive
  end
  def delete(key)
    @commands.send Delete(K).new(key)
  end
end