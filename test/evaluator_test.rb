# frozen_string_literal: true

require 'minitest/autorun'
require_relative('../lib/lexer')
require_relative('../lib/object')
require_relative('../lib/object/environment')
require_relative('../lib/parser')
require_relative('../lib/evaluator')

class TestEvaluator < MiniTest::Test
  include Evaluator

  def eval_test_helper(input)
    l = Lexer.new(input)
    p = Parser.new(l)
    program = p.parse_program
    env = Environment.new

    evaluate(program, env)
  end

  def integer_object_test_helper(object, expected)
    assert object.is_a?(Integer),
           "#{object.class} is not an integer"

    assert_equal expected, object,
                 "Object has wrong value. got=#{object}, want=#{expected}"
  end

  def boolean_object_test_helper(object, expected)
    assert(object.is_a?(TrueClass) || object.is_a?(FalseClass))
    assert_equal expected, object,
                 "Object has wrong value. got=#{object}, want=#{expected}"
  end

  def null_object_test_helper(obj)
    unless obj.nil?
      puts "object is not nil. got=#{obj}"
      return false
    end
    true
  end

  def test_eval_integer_expression
    input = Struct.new(:input, :expected)

    tests = [
      input.new('5', 5),
      input.new('10', 10),
      input.new('-5', -5),
      input.new('-10', -10),
      input.new('5 + 5 + 5 + 5 - 10', 10),
      input.new('2 * 2 * 2 * 2 * 2', 32),
      input.new('-50 + 100 + -50', 0),
      input.new('5 * 2 + 10', 20),
      input.new('20 + 2 * -10', 0),
      input.new('50 / 2 * 2 + 10', 60),
      input.new('2 * (5 + 10)', 30),
      input.new('3 * 3 * 3 + 10', 37),
      input.new('3 * (3 * 3) + 10', 37),
      input.new('(5 + 10 * 2 + 15 / 3) * 2 + -10', 50)
    ]

    tests.each do |tt|
      evaluated = eval_test_helper(tt.input)
      integer_object_test_helper(evaluated, tt.expected)
    end
  end

  def test_eval_boolean_expression
    input = Struct.new(:input, :expected)

    tests = [
      input.new('true', true),
      input.new('false', false)
    ]

    tests.each do |tt|
      evaluated = eval_test_helper(tt.input)
      boolean_object_test_helper(evaluated, tt.expected)
    end
  end

  def test_bang_operator
    input = Struct.new(:input, :expected)

    tests = [
      input.new('!true', false),
      input.new('!false', true),
      input.new('!5', false),
      input.new('!!true', true),
      input.new('!!false', false),
      input.new('!!5', true),
      input.new('1 < 2', true),
      input.new('1 > 2', false),
      input.new('1 < 1', false),
      input.new('1 > 1', false),
      input.new('1 == 1', true),
      input.new('1 != 1', false),
      input.new('1 == 2', false),
      input.new('1 != 2', true),
      input.new('true == true', true),
      input.new('false == false', true),
      input.new('true == false', false),
      input.new('true != false', true),
      input.new('false != true', true),
      input.new('(1 < 2) == true', true),
      input.new('(1 < 2) == false', false),
      input.new('(1 > 2) == true', false),
      input.new('(1 > 2) == false', true)
    ]

    tests.each do |tt|
      evaluated = eval_test_helper(tt.input)
      boolean_object_test_helper(evaluated, tt.expected)
    end
  end

  def test_if_else_expression
    input = Struct.new(:input, :expected)

    tests = [
      input.new('if (true) { 10 }', 10),
      input.new('if (false) { 10 }', nil),
      input.new('if (1) { 10 }', 10),
      input.new('if (1 < 2) { 10 }', 10),
      input.new('if (1 > 2) { 10 }', nil),
      input.new('if (1 > 2) { 10 } else { 20 }', 20),
      input.new('if (1 < 2) { 10 } else { 20 }', 10)
    ]

    tests.each do |tt|
      evaluated = eval_test_helper(tt.input)
      integer = tt.expected
      if integer.is_a?(Integer)
        integer_object_test_helper(evaluated, integer)
      else
        null_object_test_helper(evaluated)
      end
    end
  end

  def test_return_statements
    input = Struct.new(:input, :expected)

    tests = [
      input.new('return 10', 10),
      input.new('return 10; 9;', 10),
      input.new('return 2 * 5; 9;', 10),
      input.new('9; return 2 * 5; 9;', 10),
      input.new('if (10 > 1) {
                   if (10 > 1) {
                     return 10;
                   }
                   return 1;
                 }', 10)
    ]

    tests.each do |tt|
      evaluated = eval_test_helper(tt.input)
      integer = tt.expected
      if integer.is_a?(Integer)
        integer_object_test_helper(evaluated, integer)
      else
        null_object_test_helper(evaluated)
      end
    end
  end

  def test_error_handling
    input = Struct.new(:input, :expected_message)

    tests = [
      input.new(
        '5 + true;',
        'type mismatch: INTEGER + BOOLEAN'
      ),

      input.new(
        '5 + true; 5;',
        'type mismatch: INTEGER + BOOLEAN'
      ),

      input.new(
        '-true;',
        'unknown operator: -BOOLEAN'
      ),

      input.new(
        'true + false;',
        'unknown operator: BOOLEAN + BOOLEAN'
      ),

      input.new(
        '5; true + false; 5',
        'unknown operator: BOOLEAN + BOOLEAN'
      ),

      input.new(
        'if (10 > 1) { true + false; }',
        'unknown operator: BOOLEAN + BOOLEAN'
      ),

      input.new(
        '"Hello" - "World"',
        'unknown operator: STRING - STRING'
      ),

      input.new(
        '
         if (10 > 1) {
           if (10 > 1) {
             return true + false;
           }

         return 1;
        }
        ',
        'unknown operator: BOOLEAN + BOOLEAN'
      ),

      input.new(
        'foobar',
        'identifier not found: foobar'
      )
    ]

    tests.each do |tt|
      evaluated = eval_test_helper(tt.input)
      err_obj = evaluated

      unless evaluated.is_a?(Error)
        puts "no error object returned. got=#{evaluated}"
        next
      end

      assert_equal tt.expected_message, err_obj.message,
                   "wrong error message. expected=#{tt.expected_message}, got #{err_obj.message}"
    end
  end

  def test_let_statements
    input = Struct.new(:input, :expected)

    tests = [
      input.new('let a = 5; a;', 5),
      input.new('let a = 5 * 5; a;', 25),
      input.new('let a = 5; let b = a; b;', 5),
      input.new('let a = 5; let b = a; let c = a + b + 5; c;', 15)
    ]

    tests.each do |tt|
      integer_object_test_helper(eval_test_helper(tt.input), tt.expected)
    end
  end

  def test_function_object
    input = 'fn(x) { x + 2; };'

    evaluated = eval_test_helper(input)

    assert evaluated.is_a?(Function),
           "object is not Function. got=#{evaluated.class}"

    assert_equal 1, evaluated.parameters.length,
                 "function has wrong parameters. Parameters=#{evaluated.parameters.length}"

    assert_equal 'x', evaluated.parameters[0].string,
                 "parameter is not 'x'. got=#{evaluated.parameters[0]}"

    expected_body = '(x + 2)'

    assert_equal expected_body, evaluated.body.string,
                 "body is not #{expected_body}, got=#{evaluated.body.string}"
  end

  def test_function_application
    input = Struct.new(:input, :expected)
    tests = [
      input.new('let identity = fn(x) { x; }; identity(5);', 5),
      input.new('let identity = fn(x) { return x; }; identity(5);', 5),
      input.new('let double = fn(x) { x * 2; }; double(5);', 10),
      input.new('let add = fn(x,y) { x + y; }; add(5, 5);', 10),
      input.new('let add = fn(x,y) { x + y; }; add(5 + 5, add(5, 5));', 20),
      input.new('fn(x) { x; }(5)', 5)
    ]

    tests.each do |tt|
      integer_object_test_helper(eval_test_helper(tt.input), tt.expected)
    end
  end

  def test_closures
    input = '
    let newAdder = fn(x) {
      fn(y) { x + y };
    };

    let addTwo = newAdder(2);
    addTwo(2);'

    integer_object_test_helper(eval_test_helper(input), 4)
  end

  def test_string_literal
    input = '"Hello World!"'

    evaluated = eval_test_helper(input)

    assert evaluated.is_a?(String),
           "object is not String. got=#{evaluated.class}"

    assert_equal 'Hello World!', evaluated.value,
                 "String has wrong value. got=#{evaluated.value}"
  end

  def test_string_concatenation
    input = '"Hello" + " " + "World!"'

    evaluated = eval_test_helper(input)

    assert evaluated.is_a?(String),
           "object is not String. got=#{evaluated.class}"

    assert_equal 'Hello World!', evaluated.value,
                 "String has wrong value. got=#{evaluated.value}"
  end

  def test_builtin_functions
    input = Struct.new(:input, :expected)

    # TODO: add tests for builtin functions for arrays
    tests = [
      input.new('len("")', 0),
      input.new('len("four")', 4),
      input.new('len("hello world")', 11),
      input.new('len(1)', "argument to 'len' not supported, got INTEGER"),
      input.new('len("one", "two")', 'wrong number of arguments. got=2, want=1'),
      input.new('first([1, 2, 3])', 1),
      input.new('last([1, 2, 3])', 3),
      input.new('rest([1, 2, 3])', [2, 3]),
      input.new('push([1, 2, 3], 4)', [1, 2, 3, 4]),
      input.new('let a = [1, 2, 3, 4]; rest(a);', [2, 3, 4]),
      input.new('let a = [1, 2, 3, 4]; rest(rest(a));', [3, 4]),
      input.new('let a = [1, 2, 3, 4]; rest(rest(rest(a)));', [4]),
      input.new('let a = [1, 2, 3, 4]; rest(rest(rest(rest(a))));', nil),
      input.new('let a = [1, 2, 3, 4]; let b = push(a, 5); a;', [1, 2, 3, 4]),
      input.new('let a = [1, 2, 3, 4]; let b = push(a, 5); b;', [1, 2, 3, 4, 5])
    ]

    tests.each do |tt|
      evaluated = eval_test_helper(tt.input)

      case tt.expected
      when Integer
        integer_object_test_helper(evaluated, tt.expected)
      when String
        assert evaluated.is_a?(Error),
               "object is not Error. got=#{evaluated}"

        assert_equal tt.expected, evaluated.message,
                     "wrong error message. expected=#{tt.expected}, got=#{evaluated.message}"
      end
    end
  end

  def test_array_literals
    input = '[1, 2 * 2, 3 + 3]'
    evaluated = eval_test_helper(input)

    assert evaluated.is_a?(Array),
           "object is not Array. got#{evaluated}"

    assert_equal 3, evaluated.length,
                 "array has wrong number of elements. got=#{evaluated.length}"

    integer_object_test_helper(evaluated[0], 1)
    integer_object_test_helper(evaluated[1], 4)
    integer_object_test_helper(evaluated[2], 6)
  end

  def test_array_index_expressions
    input = Struct.new(:input, :expected)

    tests = [
      input.new('[1, 2, 3][0]',
                1),

      input.new('[1, 2, 3][1]',
                2),

      input.new('[1, 2, 3][2]',
                3),

      input.new('let i = 0; [1][i];',
                1),

      input.new('let myArray = [1, 2, 3]; myArray[2];',
                3),

      input.new('let myArray = [1, 2, 3]; myArray[0] + myArray[1] + myArray[2];',
                6),

      input.new('let myArray = [1, 2, 3]; let i = myArray[0]; myArray[i]',
                2),

      input.new('[1, 2, 3][3]',
                nil),

      input.new('[1, 2, 3][-1]',
                nil)
    ]

    tests.each do |tt|
      evaluated = eval_test_helper(tt.input)

      integer = tt.expected
      if integer.is_a?(Integer)
        integer_object_test_helper(evaluated, integer)
      else
        null_object_test_helper(evaluated)
      end
    end
  end
end
