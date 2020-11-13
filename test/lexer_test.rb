# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/lexer'
require_relative '../lib/token'

class TestNextToken < MiniTest::Test
  def test_normal
    input = 'let five = 5;
    let ten = 10;

     let add = fn(x, y) {
       x + y
     };
     let result = add(five, ten);
     !-/*5;
     5 < 10 > 5;

     if (5 < 10) {
         return true;
     } else {
         return false;
     }

     10 == 10;
     10 != 9;
     "foobar"
     "foo bar"
     [1, 2];
     {"foo": "bar"}
     '

    # expected tokens
    tests = [Token.new(token_type: Token::LET, literal: 'let'),
             Token.new(token_type: Token::IDENT, literal: 'five'),
             Token.new(token_type: Token::ASSIGN, literal: '='),
             Token.new(token_type: Token::INT, literal: '5'),
             Token.new(token_type: Token::SEMICOLON, literal: ';'),
             Token.new(token_type: Token::LET, literal: 'let'),
             Token.new(token_type: Token::IDENT, literal: 'ten'),
             Token.new(token_type: Token::ASSIGN, literal: '='),
             Token.new(token_type: Token::INT, literal: '10'),
             Token.new(token_type: Token::SEMICOLON, literal: ';'),
             Token.new(token_type: Token::LET, literal: 'let'),
             Token.new(token_type: Token::IDENT, literal: 'add'),
             Token.new(token_type: Token::ASSIGN, literal: '='),
             Token.new(token_type: Token::FUNCTION, literal: 'fn'),
             Token.new(token_type: Token::LPAREN, literal: '('),
             Token.new(token_type: Token::IDENT, literal: 'x'),
             Token.new(token_type: Token::COMMA, literal: ','),
             Token.new(token_type: Token::IDENT, literal: 'y'),
             Token.new(token_type: Token::RPAREN, literal: ')'),
             Token.new(token_type: Token::LBRACE, literal: '{'),
             Token.new(token_type: Token::IDENT, literal: 'x'),
             Token.new(token_type: Token::PLUS, literal: '+'),
             Token.new(token_type: Token::IDENT, literal: 'y'),
             Token.new(token_type: Token::RBRACE, literal: '}'),
             Token.new(token_type: Token::SEMICOLON, literal: ';'),
             Token.new(token_type: Token::LET, literal: 'let'),
             Token.new(token_type: Token::IDENT, literal: 'result'),
             Token.new(token_type: Token::ASSIGN, literal: '='),
             Token.new(token_type: Token::IDENT, literal: 'add'),
             Token.new(token_type: Token::LPAREN, literal: '('),
             Token.new(token_type: Token::IDENT, literal: 'five'),
             Token.new(token_type: Token::COMMA, literal: ','),
             Token.new(token_type: Token::IDENT, literal: 'ten'),
             Token.new(token_type: Token::RPAREN, literal: ')'),
             Token.new(token_type: Token::SEMICOLON, literal: ';'),
             Token.new(token_type: Token::BANG, literal: '!'),
             Token.new(token_type: Token::MINUS, literal: '-'),
             Token.new(token_type: Token::SLASH, literal: '/'),
             Token.new(token_type: Token::ASTERISK, literal: '*'),
             Token.new(token_type: Token::INT, literal: '5'),
             Token.new(token_type: Token::SEMICOLON, literal: ';'),
             Token.new(token_type: Token::INT, literal: '5'),
             Token.new(token_type: Token::LT, literal: '<'),
             Token.new(token_type: Token::INT, literal: '10'),
             Token.new(token_type: Token::GT, literal: '>'),
             Token.new(token_type: Token::INT, literal: '5'),
             Token.new(token_type: Token::SEMICOLON, literal: ';'),
             Token.new(token_type: Token::IF, literal: 'if'),
             Token.new(token_type: Token::LPAREN, literal: '('),
             Token.new(token_type: Token::INT, literal: '5'),
             Token.new(token_type: Token::LT, literal: '<'),
             Token.new(token_type: Token::INT, literal: '10'),
             Token.new(token_type: Token::RPAREN, literal: ')'),
             Token.new(token_type: Token::LBRACE, literal: '{'),
             Token.new(token_type: Token::RETURN, literal: 'return'),
             Token.new(token_type: Token::TRUE, literal: 'true'),
             Token.new(token_type: Token::SEMICOLON, literal: ';'),
             Token.new(token_type: Token::RBRACE, literal: '}'),
             Token.new(token_type: Token::ELSE, literal: 'else'),
             Token.new(token_type: Token::LBRACE, literal: '{'),
             Token.new(token_type: Token::RETURN, literal: 'return'),
             Token.new(token_type: Token::FALSE, literal: 'false'),
             Token.new(token_type: Token::SEMICOLON, literal: ';'),
             Token.new(token_type: Token::RBRACE, literal: '}'),
             Token.new(token_type: Token::INT, literal: '10'),
             Token.new(token_type: Token::EQ, literal: '=='),
             Token.new(token_type: Token::INT, literal: '10'),
             Token.new(token_type: Token::SEMICOLON, literal: ';'),
             Token.new(token_type: Token::INT, literal: '10'),
             Token.new(token_type: Token::NOT_EQ, literal: '!='),
             Token.new(token_type: Token::INT, literal: '9'),
             Token.new(token_type: Token::SEMICOLON, literal: ';'),
             Token.new(token_type: Token::STRING, literal: 'foobar'),
             Token.new(token_type: Token::STRING, literal: 'foo bar'),
             Token.new(token_type: Token::LBRACKET, literal: '['),
             Token.new(token_type: Token::INT, literal: '1'),
             Token.new(token_type: Token::COMMA, literal: ','),
             Token.new(token_type: Token::INT, literal: '2'),
             Token.new(token_type: Token::RBRACKET, literal: ']'),
             Token.new(token_type: Token::SEMICOLON, literal: ';'),
             Token.new(token_type: Token::LBRACE, literal: '{'),
             Token.new(token_type: Token::STRING, literal: 'foo'),
             Token.new(token_type: Token::COLON, literal: ':'),
             Token.new(token_type: Token::STRING, literal: 'bar'),
             Token.new(token_type: Token::RBRACE, literal: '}'),
             Token.new(token_type: Token::EOF, literal: '')]

    l = Lexer.new(input)
    tests.each do |expected|
      tok = l.lexer_next_token
      assert_equal [expected.token_type, expected.literal], [tok.token_type, tok.literal]
    end
  end
end
