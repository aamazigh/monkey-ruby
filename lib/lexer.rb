# frozen_string_literal: true

require_relative('token')

class Lexer
  def initialize(input)
    @input = input
    @ch = nil # current char under examination
    @position = 0 # current position in input
    @read_position = 0 # current reading position in input (after current char)
    read_char
  end

  def read_char
    @ch = if @read_position >= @input.length
            ''
          else
            @input[@read_position]
          end

    @position = @read_position
    @read_position += 1
  end

  def peek_char
    if @read_position >= @input.length
      @ch = ''
    else
      @input[@read_position]
    end
  end

  def read_number
    position = @position
    read_char while digit?(@ch)

    @input[position..@position - 1]
  end

  def read_identifier
    position = @position
    read_char while letter?(@ch)

    @input[position..@position - 1]
  end

  # TODO: add character escaping
  # TODO: return an error when reaching EOF
  def read_string
    position = @position + 1
    loop do
      read_char
      break if @ch == '"' || @ch == 0
    end

    @input[position..@position - 1]
  end

  def letter?(ch)
    ch >= 'a' && ch <= 'z' || ch >= 'A' && ch <= 'Z' || ch == '_'
  end

  def digit?(ch)
    ch >= '0' && ch <= '9'
  end

  def skip_whitespace
    read_char while @ch == ' ' || @ch == "\t" || @ch == "\n" || @ch == "\r"
  end

  # TODO: there is another function next_token in parser.rb. should I
  # refactor the code with namespaces?

  def lexer_next_token
    @token = Token.new
    skip_whitespace
    case @ch
    when '='
      if peek_char == '='
        ch = @ch
        read_char
        @token.literal = ch + @ch
        @token.token_type = Token::EQ
      else
        @token.literal = @ch
        @token.token_type = Token::ASSIGN
      end
    when '!'
      if peek_char == '='
        ch = @ch
        read_char
        @token.literal = ch + @ch
        @token.token_type = Token::NOT_EQ
      else
        @token.literal = @ch
        @token.token_type = Token::BANG
      end
    when '+'
      @token.literal = @ch
      @token.token_type = Token::PLUS
    when '-'
      @token.literal = @ch
      @token.token_type = Token::MINUS
    when '('
      @token.literal = @ch
      @token.token_type = Token::LPAREN
    when ')'
      @token.literal = @ch
      @token.token_type = Token::RPAREN
    when '{'
      @token.literal = @ch
      @token.token_type = Token::LBRACE
    when '}'
      @token.literal = @ch
      @token.token_type = Token::RBRACE
    when ','
      @token.literal = @ch
      @token.token_type = Token::COMMA
    when ';'
      @token.literal = @ch
      @token.token_type = Token::SEMICOLON
    when '!'
      @token.literal = @ch
      @token.token_type = Token::BANG
    when '*'
      @token.literal = @ch
      @token.token_type = Token::ASTERISK
    when '/'
      @token.literal = @ch
      @token.token_type = Token::SLASH
    when '<'
      @token.literal = @ch
      @token.token_type = Token::LT
    when '>'
      @token.literal = @ch
      @token.token_type = Token::GT
    when ''
      @token.literal = ''
      @token.token_type = Token::EOF
    when '"'
      @token.token_type = Token::STRING
      @token.literal = read_string
    when '['
      @token.literal = @ch
      @token.token_type = Token::LBRACKET
    when ']'
      @token.literal = @ch
      @token.token_type = Token::RBRACKET
    when ':'
      @token.literal = @ch
      @token.token_type = Token::COLON
    else
      if letter?(@ch)
        @token.literal = read_identifier
        @token.token_type = Token.lookup_ident(@token.literal)
        return @token
      elsif digit?(@ch)
        @token.literal = read_number
        @token.token_type = Token::INT
        return @token
      else
        @token.literal = @ch
        @token.token_type = Token::ILLEGAL
      end
    end
    read_char
    @token
  end
end
