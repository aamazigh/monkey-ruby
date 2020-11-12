# use ruby's Integer and Boolean classes that have inpect

RETURN_VALUE_OBJ = 'RETURN_VALUE'
INTEGER_OBJ = 'INTEGER'
ERROR_OBJ = 'ERROR'
BOOLEAN_OBJ = 'BOOLEAN'
FUNCTION_OBJ = 'FUNCTION'
STRING_OBJ = 'STRING'
BUILTIN_OBJ = 'BUILTIN'
ARRAY_OBJ = 'ARRAY'

class ReturnValue
  attr_accessor :value

  def initialize(value: nil)
    @value = value
  end

  def type
    RETURN_VALUE_OBJ
  end

  def inspect
    @value.inspect
  end
end

# Opening the built-in class Integer
class Integer
  def type
    INTEGER_OBJ
  end
end

# Opening the built-in true class
class TrueClass
  def type
    BOOLEAN_OBJ
  end
end

class FalseClass
  def type
    BOOLEAN_OBJ
  end
end

class Error
  attr_accessor :message

  def initialize(message)
    @message = message
  end
  
  def type
    ERROR_OBJ
  end

  def inspect
    'ERROR: ' + message
  end
end

# we will use built-in Ruby String class
# We'll add to it a method though

class String
  def type
    STRING_OBJ
  end

  def value
    self.to_s
  end
end

# extending Array class
class Array

  def type
    ARRAY_OBJ
  end

  def string
    to_a
  end
end
  
class Function
  # Functions carry their own environment with them
  attr_accessor :parameters, :body, :env

  def initialize(parameters, body, env)
    @parameters = parameters
    @body = body
    @env = env
  end

  def type
    FUNCTION_OBJ
  end

  #overrides built in inspect method
  def inspect
    params = []
    @parameters.each do |p|
      params.append(p.string)
    end

    puts "fn(" + params.join(", ") + ") {\n" + @body.string + "\n}"
  end
end

class Builtin
  attr_reader :fn

  def initialize(fn)
    @fn = fn
  end

  def type
    BUILTIN_OBJ
  end

  def string
    "builtin function"
  end
end
