# frozen_string_literal: true

require_relative('ast')
require_relative('lexer')
require_relative('token')

class Parser

  # Precedences
  LOWEST = 1
  EQUALS = 2 # ==
  LESSGREATER = 3 # > or <
  SUM = 4 # +
  PRODUCT = 5 # *
  PREFIX = 6 # -X or !X
  CALL = 7 # mFunction(X)
  INDEX = 8 # array[index]

  PRECEDENCES =
    {
      Token::EQ => EQUALS,
      Token::NOT_EQ => EQUALS,
      Token::LT => LESSGREATER,
      Token::GT => LESSGREATER,
      Token::PLUS => SUM,
      Token::MINUS => SUM,
      Token::SLASH => PRODUCT,
      Token::ASTERISK => PRODUCT,
      Token::LPAREN => CALL,
      Token::LBRACKET => INDEX
    }

  def initialize(lexer)
    @l = lexer
    @errors = []
    @prefix_parse_fns = {}
    @infix_parse_fns = {}
    next_token
    next_token

    # TODO: Should I leave these functions here?
    parse_identifier = lambda {
      Identifier.new(token: @curtoken,
                     value: @curtoken.literal)
    }

    parse_integer_literal = lambda {
      IntegerLiteral.new(token: @curtoken,
                         value: Integer(@curtoken.literal))
    }

    parse_boolean = lambda {
      Boolean.new(token: @curtoken,
                  value: curtoken_is?(Token::TRUE))
    }

    parse_prefix_expression = lambda {
      expression = PrefixExpression.new(token: @curtoken,
                                        operator: @curtoken.literal)
      next_token
      expression.right = parse_expression(PREFIX)
      expression # return the prefix expression
    }

    parse_infix_expression = lambda { |left|
       expression = InfixExpression.new(token: @curtoken,
                                              operator: @curtoken.literal,
                                              left: left)
       precedence = curprecedence
       next_token
       expression.right = parse_expression(precedence)
       expression
    }

    parse_grouped_expression = lambda {
      next_token
      exp = parse_expression(LOWEST)

      return nil unless expect_peek(Token::RPAREN)
      exp
    }

    parse_if_expression = lambda {
      expression = IfExpression.new(token: @curtoken)

      return nil unless expect_peek(Token::LPAREN)

      next_token

      expression.condition = parse_expression(LOWEST)

      return nil unless expect_peek(Token::RPAREN)
      return nil unless expect_peek(Token::LBRACE)

      expression.consequence = parse_block_statement

      if peek_token_is?(Token::ELSE)
        next_token

        return nil unless expect_peek(Token::LBRACE)

        expression.alternative = parse_block_statement
      end
      expression
    }

    parse_function_literal = lambda {
      lit = FunctionLiteral.new(token: @curtoken)

      return nil unless expect_peek(Token::LPAREN)

      lit.parameters = parse_function_parameters

      return nil unless expect_peek(Token::LBRACE)

      lit.body = parse_block_statement

      lit
    }

    parse_call_expression = lambda { |function|
      exp = CallExpression.new(token: @curtoken, function: function)
      #       exp.arguments = parse_call_arguments
      exp.arguments = parse_expression_list(Token::RPAREN)

      exp
    }

    parse_string_literal = lambda {
      StringLiteral.new(token: @curtoken, value: @curtoken.literal)
    }

    parse_array_literal = lambda {
      array = ArrayLiteral.new(token: @curtoken)
      array.elements = parse_expression_list(Token::RBRACKET)

      array
    }

    parse_hash_literal = lambda {
      hash = HashLiteral.new(token: @curtoken)
      hash.pairs = {}

      until peek_token_is?(Token::RBRACE)
        next_token

        key = parse_expression(LOWEST)

        return nil unless expect_peek(Token::COLON)

        next_token

        value = parse_expression(LOWEST)

        hash.pairs[key] = value

        return nil if !peek_token_is?(Token::RBRACE) && !expect_peek(Token::COMMA)
      end

      return nil unless expect_peek(Token::RBRACE)

      hash
    }

    def parse_expression_list(end_of_list_token)
      list = []

      if peek_token_is?(end_of_list_token)
        next_token
        return list
      end

      next_token
      list.append(parse_expression(LOWEST))

      while peek_token_is?(Token::COMMA)
        next_token
        next_token
        list.append(parse_expression(LOWEST))
      end

      return nil unless expect_peek(end_of_list_token)

      list
    end

    parse_index_expression = lambda { |left|
      exp = IndexExpression.new(token: @curtoken, left: left)

      next_token
      exp.index = parse_expression(LOWEST)

      return nil unless expect_peek(Token::RBRACKET)

      exp
    }

    register_prefix(Token::IDENT, parse_identifier)
    register_prefix(Token::INT, parse_integer_literal)
    register_prefix(Token::BANG, parse_prefix_expression)
    register_prefix(Token::MINUS, parse_prefix_expression)
    register_prefix(Token::TRUE, parse_boolean)
    register_prefix(Token::FALSE, parse_boolean)
    register_prefix(Token::LPAREN, parse_grouped_expression)
    register_prefix(Token::IF, parse_if_expression)
    register_prefix(Token::ELSE, parse_if_expression)
    register_prefix(Token::FUNCTION, parse_function_literal)
    register_infix(Token::PLUS, parse_infix_expression)
    register_infix(Token::MINUS, parse_infix_expression)
    register_infix(Token::SLASH, parse_infix_expression)
    register_infix(Token::ASTERISK, parse_infix_expression)
    register_infix(Token::EQ, parse_infix_expression)
    register_infix(Token::NOT_EQ, parse_infix_expression)
    register_infix(Token::LT, parse_infix_expression)
    register_infix(Token::GT, parse_infix_expression)
    register_infix(Token::LPAREN, parse_call_expression)
    register_prefix(Token::STRING, parse_string_literal)
    register_prefix(Token::LBRACKET, parse_array_literal)
    register_infix(Token::LBRACKET, parse_index_expression)
    register_prefix(Token::LBRACE, parse_hash_literal)
  end

  def peek_precedence
    if (p = PRECEDENCES[@peek_token.token_type])
      p
    else
      LOWEST
    end
  end

  def curprecedence
    if (p = PRECEDENCES[@curtoken.token_type])
      p
    else
      LOWEST
    end
  end

  def Errors
    @errors
  end

  ## tt: tokentype
  def peek_error(tok)
    msg = "expected next token to be #{tok}, got #{@peek_token.token_type} instead"
    @errors.append(msg)
  end

  def next_token
    @curtoken = @peek_token
    @peek_token = @l.NextToken
  end

  def parse_program
    program = Program.new
    program.statements = []

    until curtoken_is?(Token::EOF)
      stmt = parse_statement
      program.statements.push(stmt) if stmt != nil
      next_token
    end

    program
  end

  def parse_statement
    case @curtoken.token_type
    when Token::LET
      parse_let_statement
    when Token::RETURN
      parse_return_statement
    else
      parse_expression_statement
    end
  end

  def parse_let_statement
    stmt = LetStatement.new
    stmt.token = @curtoken

    return nil unless expect_peek(Token::IDENT)

    stmt.name = Identifier.new(token: @curtoken, value: @curtoken.literal)

    return nil unless expect_peek(Token::ASSIGN)

    next_token

    stmt.value = parse_expression(LOWEST)
    #    next_token until curtoken_is?(Token::SEMICOLON)

    next_token if peek_token_is?(Token::SEMICOLON)

    stmt
  end

  def parse_return_statement
    stmt = ReturnStatement.new # letstatement from the ast
    stmt.token = @curtoken
    next_token

    stmt.return_value = parse_expression(LOWEST)

    next_token if peek_token_is?(Token::SEMICOLON)

    stmt
  end

  def parse_expression_statement
    stmt = ExpressionStatement.new(token: @curtoken,
                                   expression: parse_expression(LOWEST))

    # The semicolon here is optional. If it's not there, stmt is
    # nonetheless returned Optional semicolons after expression
    # statements allow commands like 5 + 5 in the REPL
    next_token if peek_token_is?(Token::SEMICOLON)

    stmt
  end

  def parse_expression(precedence)
    prefix = @prefix_parse_fns[@curtoken.token_type]

    if prefix.nil?
      no_prefix_parse_fn_error(@curtoken.token_type)
      return nil
    end

    left_exp = prefix.call

    while !peek_token_is?(Token::SEMICOLON) && precedence < peek_precedence
      infix = @infix_parse_fns[@peek_token.token_type]
      return left_exp if infix.nil?

      next_token
      left_exp = infix.call(left_exp)
    end

    left_exp
  end

  def parse_block_statement
    block = BlockStatement.new(token: @curtoken)
    block.statements = []

    next_token

    while !curtoken_is?(Token::RBRACE) && !curtoken_is?(Token::EOF)
      stmt = parse_statement
      block.statements.push(stmt) unless stmt.nil?
      next_token
    end

    block
  end

  def parse_function_parameters
    identifiers = []

    if peek_token_is?(Token::RPAREN)
      next_token
      return identifiers
    end

    next_token

    ident = Identifier.new(token: @curtoken, value: @curtoken.literal)

    identifiers.append(ident)

    while peek_token_is?(Token::COMMA)
      next_token
      next_token
      ident = Identifier.new(token: @curtoken, value: @curtoken.literal)
      identifiers.append(ident)
    end

    return nil unless expect_peek(Token::RPAREN)

    identifiers
  end

  def parse_call_arguments
    args = []

    if peek_token_is?(Token::RPAREN)
      next_token

      return args
    end

    next_token
    args.append(parse_expression(LOWEST))

    while peek_token_is?(Token::COMMA)
      next_token
      next_token
      args.append(parse_expression(LOWEST))
    end

    return nil unless expect_peek(Token::RPAREN)

    args
  end

  def register_prefix(token_type, fn)
    @prefix_parse_fns.store(token_type, fn)
  end

  def register_infix(token_type, fn)
    @infix_parse_fns.store(token_type, fn)
  end

  def no_prefix_parse_fn_error(tokentype)
    msg = "no prefix parse function for #{tokentype} found"
    @errors.append(msg)
  end

  def curtoken_is?(tok)
    @curtoken.token_type == tok
  end

  def peek_token_is?(tok)
    @peek_token.token_type == tok
  end

  def expect_peek(tok)
    # TODO: you should rename this method.  It actually advances the
    # token, which is not clear for the method's name
    if peek_token_is?(tok)
      next_token
      true
    else
      peek_error(tok)
      false
    end
  end
end
