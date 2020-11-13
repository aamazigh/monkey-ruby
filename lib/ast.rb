# frozen_string_literal: false

class Program
  attr_accessor :statements

  def initialize(statements: [])
    @statements = statements
  end

  def token_literal
    if len(@statements) > 0
      @statements[0].token_literal
    else
      ''
    end
  end

  def string
    output = ''
    @statements.each do |s|
      output << s.string
    end
    output
  end
end

class LetStatement
  attr_accessor :token, :name, :value

  def initialize(token: nil, name: nil, value: nil)
    @token = token
    @name = name
    @value = value
  end

  def token_literal
    @token.literal
  end

  def string
    str = @token.literal + ' ' + @name.string + ' = '
    str += @value.string if @value
    str += ';'
    str
  end
end

class Identifier
  attr_accessor :token, :value

  def initialize(token: nil, value: nil)
    @token = token
    @value = value
  end

  def token_literal
    @token.literal
  end

  def string
    @value
  end
end

class ReturnStatement
  attr_accessor :token, :return_value

  def initialize(token: nil, return_value: nil)
    @token = token
    @return_value = return_value
  end

  def token_literal
    @token.literal
  end

  def string
    if @return_value
      str = @token.literal + ' '
      str += @value.string if @value
      str += ';'
      str
    end
  end
end

class ExpressionStatement
  attr_accessor :token, :expression

  def initialize(token: nil, expression: nil)
    @token = token
    @expression = expression
  end

  def token_literal
    @token.literal
  end

  def string
    @expression&.string
  end
end

class IntegerLiteral
  attr_accessor :token, :value

  def initialize(token: nil, value: nil)
    @token = token
    @value = value
  end

  def token_literal
    @token.literal
  end

  def string
    @token.literal
  end
end

class Boolean
  attr_accessor :token, :value

  def initialize(token: nil, value: nil)
    @token = token
    @value = value
  end

  def token_literal
    @token.literal
  end

  def string
    @token.literal
  end
end

class PrefixExpression
  attr_accessor :token, :operator, :right

  def initialize(token: nil, operator: nil, right: nil)
    @token = token
    @operator = operator
    @right = right
  end

  def token_literal
    @token.literal
  end

  def string
    '(' + operator + @right.string + ')'
  end
end

class InfixExpression
  attr_accessor :token, :left, :operator, :right

  def initialize(token: nil, left: nil, operator: nil, right: nil)
    @token = token
    @left = left
    @right = right
    @operator = operator
  end

  def token_literal
    @token.literal
  end

  def string
    '(' + @left.string + ' ' + @operator + ' ' + @right.string + ')'
  end
end

class IfExpression
  attr_accessor :token, :condition, :consequence, :alternative

  def initialize(token: nil, condition: nil, consequence: nil, alternative: nil)
    @token = token
    @condition = condition
    @consequence = consequence
    @alternative = alternative
  end

  def token_literal
    @token.literal
  end

  def string
    output = ''
    output << 'if' + @condition.string + ' ' + consequence.string
    output << 'else ' + alternative.string if alternative
    output
  end
end

class BlockStatement
  attr_accessor :token, :statements

  def initialize(token: nil, statements: [])
    @token = token
    @statements = statements
  end

  def token_literal
    @token.literal
  end

  def string
    output = ''
    @statements.each do |s|
      output += s.string
    end
    output
  end
end

class FunctionLiteral
  attr_accessor :token, :parameters, :body

  def initialize(token: nil, parameters: nil, body: nil)
    @token = token
    @paramameters = parameters
    @body = body
  end

  def token_literal
    @token.literal
  end

  def string
    params = []
    parameters.each do |p|
      params.append(p.string)
    end
    @token.literal + '(' + params.join(', ') + ')' + '{ ' + body.string + ' }'
  end
end

class CallExpression
  attr_accessor :token, # the '(' token
                :function,
                :arguments

  def initialize(token: nil, function: nil, arguments: [])
    @token = token
    @function = function
    @arguments = arguments
  end

  def token_literal
    @token.literal
  end

  def string
    args = []

    arguments.each do |arg|
      args.append(arg.string)
    end

    @function.string + '(' + args.join(', ') + ')'
  end
end

class StringLiteral
  attr_accessor :token, :value

  def initialize(token: nil, value: nil)
    @token = token
    @value = value
  end

  def expression_node; end

  def token_literal
    @token.literal
  end

  def string
    @token.literal
  end
end

class ArrayLiteral
  attr_accessor :token, :elements

  def initialize(token, elements = nil)
    @token = token
    @elements = elements
  end

  def token_literal
    @token.literal
  end

  def string
    el_container = []
    elements.each do |el|
      el_container.append(el.string)
    end
    '[' + el_container.join(', ') + ']'
  end
end

class IndexExpression
  attr_accessor :token, :left, :index

  def initialize(token:, left:, index: nil)
    @token = token
    @left = left
    @index = index
  end

  def token_literal
    @token.literal
  end

  def string
    '(' + left.string + '[' + index.string + '])'
  end
end

class HashLiteral
  attr_accessor :token, :pairs

  def initialize(token:, pairs: {})
    @token = token
    @pairs = pairs
  end

  def token_literal
    @token.literal
  end

  def string
    p = []
    pairs.each_pair do |key, value|
      p.append("#{key}: #{value}")
    end
    '{' + p.join(', ') + '}'
  end
end
