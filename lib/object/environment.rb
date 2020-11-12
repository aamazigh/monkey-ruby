class Environment
  attr_writer :outer

  def initialize
    @store = {}
    @outer = nil
  end

  def get_val(name)
    return @outer.get_val(name) if @store[name].nil? && !@outer.nil?

    @store[name]
  end

  def set_val(name, val)
    @store[name] = val
  end
end
