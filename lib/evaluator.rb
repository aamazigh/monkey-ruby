require_relative('evaluator/builtins')
require_relative('object')

module Evaluator
  def eval_prefix_expression(operator, right)
    case operator
    when '!'
      eval_bang_operator_expression(right)
    when '-'
      eval_minus_prefix_operator_expression(right)
    else
      Error.new("unknown operator: #{operator}, #{right.type}")
    end
  end

  def eval_minus_prefix_operator_expression(right)
    if right.type != INTEGER_OBJ
      Error.new("unknown operator: -#{right.type}")
    else
      return -right if right.is_a?(Integer)
    end
  end

  def eval_bang_operator_expression(right)
    case right
    when true then false
    when false then true
    when nil then true
    else false
    end
  end

  def eval_infix_expression(operator, left, right)
    if left.is_a?(Integer) && right.is_a?(Integer)
      eval_integer_infix_expression(operator, left, right)
    elsif left.type == STRING_OBJ && right.type == STRING_OBJ
      eval_string_infix_expression(operator, left, right)
    elsif operator == '=='
      left == right
    elsif operator == '!='
      left != right
    elsif left.type != right.type
      Error.new("type mismatch: #{left.type} #{operator} #{right.type}")
    else
      Error.new("unknown operator: #{left.type} #{operator} #{right.type}")
    end
  end

  def eval_string_infix_expression(operator, left, right)
    # TODO: add string comparison == and !=
    return Error.new("unknown operator: #{left.type} #{operator} #{right.type}") if operator != '+'

    String.new(left.value + right.value)
  end

  def eval_integer_infix_expression(operator, left, right)
    left_val = left
    right_val = right

    case operator
    when '+' then left_val + right_val
    when '-' then left_val - right_val
    when '*' then left_val * right_val
    when '/' then left_val / right_val
    when '<' then left_val < right_val
    when '>' then left_val > right_val
    when '==' then left_val == right_val
    when '!=' then left_val != right_val
    else
      Error.new("unknown operator: #{left.type}, #{operator}, #{right.type}")
    end
  end

  def eval_if_expression(ie, env)
    condition = evaluate(ie.condition, env)
    return condition if is_error(condition)

    if is_truthy(condition) then evaluate(ie.consequence, env)
    elsif !ie.alternative.nil?
      evaluate(ie.alternative, env)
    end
  end

  def is_truthy(obj)
    case obj
    when nil then false
    when true then true
    when false then false
    else true
    end
  end

  def eval_program(stmts, env)
    result = nil
    stmts.each do |statement|
      result = evaluate(statement, env)

      case result
      when ReturnValue
        return result.value
      when Error
        return result
      end

      # if result.is_a?(ReturnValue)
      #   return result.value
      # end
    end
    result
  end

  def eval_block_statement(block, env)
    result = nil
    block.each do |statement|
      result = evaluate(statement, env)

      next if result.nil?

      rt = result.type
      return result if [RETURN_VALUE_OBJ, ERROR_OBJ].include?(rt)
    end

    result
  end

  def eval_identifier(node, env)
    val = env.get_val(node.value)

    if builtin = $builtins[node.value]
      return builtin
    end

    return Error.new("identifier not found: #{node.value}") if val.nil?

    val
  end

  def is_error(obj)
    return obj.type == ERROR_OBJ unless obj.nil?

    false
  end

  def eval_expressions(exps, env)
    result = []

    exps.each do |e|
      evaluated = evaluate(e, env)
      return evaluated if is_error(evaluated)

      result.append(evaluated)
    end
    result
  end

  def apply_function(function, args)
    case function
    when Function
      extended_env = extend_function_env(function, args)
      evaluated = evaluate(function.body, extended_env)
      unwrap_return_value(evaluated)
    when Builtin
      function.fn.call(*args)
    else
      Error.new("not a function: #{function.type}")
    end
  end
end

def new_enclosed_environment(outer)
  return Error.new("not an environment: #{outer.type}") unless outer.is_a?(Environment)

  env = Environment.new
  env.outer = outer
  env
end

def extend_function_env(fn, args)
  # TODO: here lies the problem
  env = Environment.new

  env = new_enclosed_environment(fn.env)

  fn.parameters.each_with_index do |param, param_idx|
    env.set_val(param.value, args[param_idx])
  end
  env
end

def unwrap_return_value(obj)
  return obj.value if obj.is_a?(ReturnValue)

  obj
end

def eval_index_expression(left, index)
  if left.type == ARRAY_OBJ && index.type == INTEGER_OBJ
    eval_array_index_expression(left, index)
  else
    Error.new("index operator not supported: #{left.type}")
  end
end

def eval_array_index_expression(array, index)
  max = array.length - 1

  return nil if index < 0 || index > max

  array[index]
end

# TODO: Evaluating hashes

def evaluate(node, env)
  case node
  when Program
    eval_program(node.statements, env)
  when ExpressionStatement
    evaluate(node.expression, env)
  when IntegerLiteral
    node.value
  when Boolean
    node.value
  when PrefixExpression
    right = evaluate(node.right, env)
    return right if is_error(right)

    eval_prefix_expression(node.operator, right)
  when InfixExpression
    left = evaluate(node.left, env)
    return left if is_error(left)

    right = evaluate(node.right, env)
    return right if is_error(right)

    eval_infix_expression(node.operator, left, right)
  when BlockStatement
    eval_block_statement(node.statements, env)
  when IfExpression
    eval_if_expression(node, env)
  when ReturnStatement
    val = evaluate(node.return_value, env)
    return val if is_error(val)

    ReturnValue.new(value: val)
  when LetStatement
    val = evaluate(node.value, env)
    return val if is_error(val)

    env.set_val(node.name.value, val)
  when Identifier
    eval_identifier(node, env)
  when FunctionLiteral
    params = node.parameters
    body = node.body
    Function.new(params, body, env)
  when CallExpression
    function = evaluate(node.function, env)
    return function if is_error(function)

    args = eval_expressions(node.arguments, env)
    return args[0] if args.length == 1 && is_error(args[0])

    apply_function(function, args)
  when StringLiteral
    node.value
  when ArrayLiteral
    elements = eval_expressions(node.elements, env)

    return elements[0] if elements.length == 1 && is_error(elements[0])

    elements
  when IndexExpression
    left = evaluate(node.left, env)
    return left if is_error(left)

    index = evaluate(node.index, env)

    return index if is_error(index)

    eval_index_expression(left, index)

  else
    false
  end
end
