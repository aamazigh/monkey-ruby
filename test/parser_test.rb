# frozen_string_literal: true

require 'minitest/autorun'
require_relative('../lib/ast')
require_relative('../lib/lexer')
require_relative('../lib/parser')

class TestParser < MiniTest::Test
  def check_parser_errors(parser)
    errors = parser.errors

    return if errors.empty?

    puts "parser has #{errors.length} errors"

    errors.each do |err|
      puts "parser error: #{err}"
    end
  end

  def literal_expression_test_helper(expression, expected)
    if expected.is_a?(Integer)
      integer_literal_test_helper(expression, expected)
    elsif expected.is_a?(String)
      identifier_test_helper(expression, expected)
    elsif expected.is_a?(TrueClass) || expected.is_a?(FalseClass)
      boolean_literal_test_helper(expression, expected)
    else
      puts 'error'
      nil
    end
  end

  def infix_expression_test_helper(expression, left, _operator, right)
    literal_expression_test_helper(expression.left, left)
    literal_expression_test_helper(expression.right, right)
  end

  def identifier_test_helper(expression, value)
    assert_equal value, expression.value
    assert_equal value, expression.TokenLiteral
  end

  def integer_literal_test_helper(expression, value)
    assert_equal value, expression.value
    assert_equal value.to_s, expression.TokenLiteral
  end

  def boolean_literal_test_helper(expression, value)
    assert_equal value, expression.value
    assert_equal value.to_s, expression.TokenLiteral
  end

  def let_statement_test_helper(statement, name)
    assert_equal 'let', statement.TokenLiteral
    assert_equal name, statement.name.value
    assert_equal name, statement.name.TokenLiteral
  end

  def boolean_literal_test_helper(expression, value)
    assert_equal value, expression.value
    assert_equal value.to_s, expression.TokenLiteral
  end

  def test_let_statements
    input = Struct.new(:input, :expected_identifier, :expected_value)

    tests = [
      input.new('let x = 5;', 'x', 5),
      input.new('let y = true;', 'y', true),
      input.new('let foobar = y;', 'foobar', 'y')
    ]

    tests.each do |tt|
      l = Lexer.new(tt.input)
      p = Parser.new(l)
      program = p.parse_program
      check_parser_errors(p)

      assert_equal 1, program.statements.length,
                   "program.statements doesn't contain 1 statement.
                   Got #{program.statements.length}"

      stmt = program.statements[0]

      let_statement_test_helper(stmt, tt.expected_identifier)

      val = stmt.value
      literal_expression_test_helper(val, tt.expected_value)
    end
  end

  def test_return_statements
    input = '
return 5;
return z;
return (1 + 3);
return true;
'
    l = Lexer.new(input)
    p = Parser.new(l)
    puts p.errors
    program = p.parse_program
    check_parser_errors(p)

    assert program, 'parse_program returned nil'

    assert_equal 4, program.statements.length

    program.statements.each do |return_stmt|
      assert_equal 'return', return_stmt.TokenLiteral
    end
  end

  def test_identifier_expression
    input = 'foobar;'

    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    assert_equal 1, program.statements.length

    ident = program.statements[0]

    assert_equal 'foobar', ident.expression.value
  end

  def test_integer_literal
    input = '5;'

    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    assert_equal 1, program.statements.length

    literal = program.statements[0]

    assert_equal 5, literal.expression.value
  end

  def test_parsing_prefix_expressions
    input = Struct.new(:input, :operator, :integerValue)
    prefix_tests = [
      input.new('!5;', '!', 5),
      input.new('-15;', '-', 15),
      input.new('!true;', '!', true),
      input.new('!false', '!', false)
    ]

    prefix_tests.each do |tt|
      l = Lexer.new(tt.input)
      p = Parser.new(l)
      program = p.parse_program
      check_parser_errors(p)

      assert_equal 1, program.statements.length

      stmt = program.statements[0]

      assert_equal tt.operator, stmt.expression.operator
      integer_literal_test_helper(stmt.expression.right, tt.integerValue)
    end
  end

  def test_parsing_infix_expressions
    input = Struct.new(:input, :leftValue, :operator, :rightValue)
    prefix_tests = [input.new('5 + 5;', 5, '+', 5),
                    input.new('5 - 5;', 5, '-', 5),
                    input.new('5 * 5;', 5, '*', 5),
                    input.new('5 / 5;', 5, '/', 5),
                    input.new('5 > 5;', 5, '>', 5),
                    input.new('5 < 5;', 5, '<', 5),
                    input.new('5 == 5;', 5, '==', 5),
                    input.new('5 != 5;', 5, '!=', 5),
                    input.new('true == true', true, '==', true),
                    input.new('true != false', true, '!=', false),
                    input.new('false == false', false, '==', false)]

    prefix_tests.each do |tt|
      l = Lexer.new(tt.input)
      p = Parser.new(l)
      program = p.parse_program
      check_parser_errors(p)

      assert_equal 1, program.statements.length

      stmt = program.statements[0]

      infix_expression_test_helper(stmt.expression,
                                   tt.leftValue, tt.operator, tt.rightValue)
    end
  end

  def test_operator_preceding_parsing
    input = Struct.new(:input, :expected)
    tests = [

      input.new('-a * b',
                '((-a) * b)'),

      input.new('!-a',
                '(!(-a))'),

      input.new('a + b + c',
                '((a + b) + c)'),

      input.new('a + b - c',
                '((a + b) - c)'),

      input.new('a * b * c',
                '((a * b) * c)'),

      input.new('a * b / c',
                '((a * b) / c)'),

      input.new('a + b / c',
                '(a + (b / c))'),

      input.new('a + b * c + d / e - f',
                '(((a + (b * c)) + (d / e)) - f)'),

      input.new('3 + 4; -5 * 5',
                '(3 + 4)((-5) * 5)'),

      input.new('5 > 4 == 3 < 4',
                '((5 > 4) == (3 < 4))'),

      input.new('5 < 4 != 3 > 4',
                '((5 < 4) != (3 > 4))'),

      input.new('3 + 4 * 5 == 3 * 1 + 4 * 5',
                '((3 + (4 * 5)) == ((3 * 1) + (4 * 5)))'),

      input.new('true',
                'true'),

      input.new('false',
                'false'),

      input.new('3 > 5 == false',
                '((3 > 5) == false)'),

      input.new('3 < 5 == true',
                '((3 < 5) == true)'),

      # Grouped expressions
      input.new('1 + (2 + 3) + 4',
                '((1 + (2 + 3)) + 4)'),

      input.new('(5 + 5) * 2',
                '((5 + 5) * 2)'),

      input.new('2 / (5 + 5)',
                '(2 / (5 + 5))'),

      input.new('-(5 + 5)',
                '(-(5 + 5))'),

      input.new('!(true == true)',
                '(!(true == true))'),

      # test function calls precedence
      input.new('a + add(b * c) + d',
                '((a + add((b * c))) + d)'),

      input.new('add(a, b, 1, 2 * 3, 4 + 5, add(6, 7 * 8))',
                'add(a, b, 1, (2 * 3), (4 + 5), add(6, (7 * 8)))'),

      input.new('add(a + b + c * d / f + g)',
                'add((((a + b) + ((c * d) / f)) + g))'),

      # test array operator precedence
      input.new('a * [1, 2, 3, 4][b * c] * d',
                '((a * ([1, 2, 3, 4][(b * c)])) * d)'),

      input.new('add(a * b[2], b[1], 2 * [1,  2][1])',
                'add((a * (b[2])), (b[1]), (2 * ([1, 2][1])))')

    ]

    tests.each do |tt|
      l = Lexer.new(tt.input)
      p = Parser.new(l)
      program = p.parse_program
      check_parser_errors(p)
      actual = program.string
      assert_equal tt.expected, actual
    end
  end

  def test_boolean_expression
    input = '
true;
'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    bool = program.statements[0]

    assert_equal true, bool.expression.value
  end

  def test_if_expression
    input = 'if (x < y) { x }'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    assert_equal 1, program.statements.length

    exp = program.statements[0].expression

    infix_expression_test_helper(exp.condition, 'x', '<', 'y')

    assert_equal 1, exp.consequence.statements.length

    consequence = exp.consequence.statements[0]

    identifier_test_helper(consequence.expression, 'x')

    assert_nil exp.alternative
  end

  def test_if_else_expression
    input = 'if (x < y) { x } else { y }'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    assert_equal 1, program.statements.length

    exp = program.statements[0].expression

    infix_expression_test_helper(exp.condition, 'x', '<', 'y')

    assert_equal 1, exp.consequence.statements.length

    consequence = exp.consequence.statements[0]

    alternative = exp.alternative.statements[0]
    identifier_test_helper(consequence.expression, 'x')
    identifier_test_helper(alternative.expression, 'y')
  end

  def test_function_literal_parsing
    input = 'fn(x, y) { x + y; }'

    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    assert_equal 1, program.statements.length

    function = program.statements[0].expression

    assert_equal 2, function.parameters.length,
                 "Function literal parameters wrong.
               Expected 2, got #{function.parameters.length}"

    literal_expression_test_helper(function.parameters[0], 'x')
    literal_expression_test_helper(function.parameters[1], 'y')

    assert_equal 1, function.body.statements.length,
                 "function.body.statements should have 1 statement.
               Got #{function.body.statements.length}"

    infix_expression_test_helper(function.body.statements[0].expression, 'x', '+', 'y')
  end

  def test_function_parameter_parsing
    input = Struct.new(:input, :expected_params)

    tests = [
      input.new('fn() {};', []),
      input.new('fn(x) {};', ['x']),
      input.new('fn(x, y, z) {};', %w[x y z])
    ]

    tests.each do |tt|
      l = Lexer.new(tt.input)
      p = Parser.new(l)
      program = p.parse_program
      check_parser_errors(p)

      function = program.statements[0].expression

      assert_equal tt.expected_params.length, function.parameters.length,
                   "parameters length wrong.
                   Expected #{tt.expected_params.length}.
                   got #{function.parameters.length}"

      tt.expected_params.each_with_index do |ident, i|
        literal_expression_test_helper(function.parameters[i], ident)
      end
    end
  end

  def test_call_expression_parsing

    input = 'add(1, 2 * 3, 4 + 5);'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    assert_equal 1, program.statements.length,
                 'we should have 1 statement. got #{program.statements.length}'

    exp = program.statements[0].expression
    identifier_test_helper(exp.function, 'add')

    assert_equal 3, exp.arguments.length,
                 'wrong length of arguments. got=#{exp.arguments.length}'

    literal_expression_test_helper(exp.arguments[0], 1)
    infix_expression_test_helper(exp.arguments[1], 2, '*', 3)
    infix_expression_test_helper(exp.arguments[2], 4, '+', 5)
  end

  def test_string_literal_expression
    input = '"hello world";'

    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    stmt = program.statements[0]

    literal = stmt.expression

    assert literal.is_a?(StringLiteral),
           "exp not StringLiteral. got=#{literal.class}"

    assert_equal 'hello world', literal.value,
                 "literal.value is not \"hello world\", got #{literal.value}"
  end

  def test_parsing_array_literals
    input = '[1, 2 * 2, 3 + 3]'

    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    stmt = program.statements[0]

    array = stmt.expression

    assert array.is_a?(ArrayLiteral),
           "exp not ArrayLiteral. got=#{stmt.expression}"

    assert_equal 3, array.elements.length,
                 "len(array.elements) not 3. got=#{array.elements.length}"

    integer_literal_test_helper(array.elements[0], 1)
    infix_expression_test_helper(array.elements[1], 2, '*', 2)
    infix_expression_test_helper(array.elements[2], 3, '+', 3)
  end

  def test_parsing_index_expression
    input = 'myArray[1 + 1]'

    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    stmt = program.statements[0]

    index_exp = stmt.expression

    assert index_exp.is_a?(IndexExpression),
           "exp not IndexExpression. got=#{stmt.expression}"

    return unless identifier_test_helper(index_exp.left, 'myArray')
    return unless infix_expression_test_helper(index_exp.index, 1, '+', 1)
  end

  def test_parsing_hash_literals_stringkeys
    input = '{"one": 1, "two":2, "three": 3}'

    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    stmt = program.statements[0]
    hash = stmt.expression

    assert hash.is_a?(HashLiteral),
           "exp is not HashLiteral. got=#{stmt.expression}"

    assert_equal 3, hash.pairs.length,
                 "hash.pairs has wrong length. got=#{hash.pairs.length}"

    expected = { 'one' => 1, 'two' => 2, 'three' => 3 }

    hash.pairs.each_pair do |key, value|
      literal = key

      assert literal.is_a?(StringLiteral),
             "key is not StringLiteral. got=#{key}"

      expected_value = expected[literal.string]

      integer_literal_test_helper(value, expected_value)
    end
  end

  def test_parsing_empty_hash_literal
    input = '{}'
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    stmt = program.statements[0]
    hash = stmt.expression

    assert hash.is_a?(HashLiteral),
           "exp is not HashLiteral. got=#{stmt.expression}"

    assert_equal 0, hash.pairs.length,
                 "hash.pairs has wrong length. got=#{hash.pairs.length}"
  end

  def test_parsing_hash_literals_with_expressions
    input = '{"one": 0 + 1, "two": 10 - 8, "three": 15 / 5}'

    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    check_parser_errors(p)

    stmt = program.statements[0]
    hash = stmt.expression

    assert hash.is_a?(HashLiteral),
           "exp is not HashLiteral. got=#{stmt.expression}"

    assert_equal 3, hash.pairs.length,
                 "hash.pairs has wrong length. got=#{hash.pairs.length}"
    tests =
      { 'one' => lambda { |e|
                   infix_expression_test_helper(e, 0, '+', 1)
                 },

        'two' => lambda { |e|
                   infix_expression_test_helper(e, 10, '-', 8)
                 },

        'three' => lambda { |e|
                     infix_expression_test_helper(e, 15, '/', 5)
                   } }

    hash.pairs.each_pair do |key, value|
      literal = key

      assert literal.is_a?(StringLiteral),
             "key is not StringLiteral. got=#{key}"

      test_func = tests[literal.string]

      assert test_func,
             "No test function for key #{literal.string} found"

      test_func.call(value)
    end
  end
end
