require 'readline'
require_relative('../lib/lexer')
require_relative('../lib/parser')
require_relative('../lib/evaluator')
require_relative('../lib/object')
require_relative('../lib/object/environment')

# TODO: improve editing functionalities of the REPL

class Repl
  include Evaluator
  def self.run
    puts 'Welcome to the ruby implementation of the Monkey programming language!'
    env = Environment.new
    while line = Readline.readline('>> ', true)

      l = Lexer.new(line)
      p = Parser.new(l)

      program = p.parse_program

      if p.errors.length != 0
        print_parser_errors(p.errors)
        next
      end

      evaluated = evaluate(program, env)
      p evaluated unless evaluated.nil?
    end
  end

  private

  def print_parser_errors(errors)
    errors.each do |err|
      puts "\t" + err + "\n"
    end
  end
end
