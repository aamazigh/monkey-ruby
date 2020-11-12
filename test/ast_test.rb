# frozen_string_literal: true

require 'minitest/autorun'
require_relative('../lib/token')
require_relative('../lib/ast')

class TestString < MiniTest::Test
  def test_normal
    program = Program.new
    program.statements = [
      LetStatement.new(token: Token.new(token_type: Token::LET,
                                        literal: 'let'),
                       name: Identifier.new(token: Token.new(token_type: Token::IDENT, literal: 'myVar'),
                                            value: 'myVar'),
                       value: Identifier.new(token: Token.new(token_type: Token::IDENT, literal: 'anotherVar'),
                                             value: 'anotherVar'))
    ]

    assert_equal 'let myVar = anotherVar;', program.string
  end
end
