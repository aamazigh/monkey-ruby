# frozen_string_literal: true

class Token
  attr_accessor :token_type, :literal

  def initialize(token_type: '', literal: '')
    @token_type = token_type
    @literal = literal
  end

  ILLEGAL = 'ILLEGAL'
  EOF = 'EOF'

  # identifiers and literal
  IDENT = 'IDENT'
  INT = 'INT'

  # Operators
  ASSIGN = '='
  PLUS = '+'
  MINUS = '-'
  BANG = '!'
  ASTERISK = '*'
  SLASH = '/'

  # Delimiters
  COMMA = ','
  SEMICOLON = ';'

  COLON = ':'

  LPAREN = '('
  RPAREN = ')'
  LBRACE = '{'
  RBRACE = '}'

  LBRACKET = '['
  RBRACKET = ']'

  STRING = 'STRING'

  # Keywords
  FUNCTION = 'FUNCTION'
  LET = 'LET'

  # Operators

  LT = '<'
  GT = '>'

  TRUE = 'true'
  FALSE = 'false'
  IF = 'if'
  ELSE = 'else'
  RETURN = 'return'

  EQ = '=='
  NOT_EQ = '!='

  @keywords = { 'fn' => FUNCTION,
                'let' => LET,
                'true' => TRUE,
                'false' => FALSE,
                'if' => IF,
                'else' => ELSE,
                'return' => RETURN }

  def self.lookup_ident(ident)
    if @keywords.key?(ident)
      @keywords[ident]
    else
      IDENT
    end
  end
end
