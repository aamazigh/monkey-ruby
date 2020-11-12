require_relative('../evaluator')
require_relative('../object')

$builtins = {}
$builtins['len'] =
  Builtin.new(
    lambda { |*args|
      if args.length != 1
        return Error.new(
          "wrong number of arguments. got=#{args.length}, want=1"
        )
      end

      case arg = args[0]
      when Array
        return arg.length
      when String
        return arg.value.length
      else
        return Error.new(
          "argument to 'len' not supported, got #{args[0].type}"
        )
      end
    }
  )

$builtins['first'] =
  Builtin.new(
    lambda { |*args|
      if args.length != 1
        return Error.new(
          "wrong number of arguments. got=#{args.length}, want=1"
        )
      end

      if args[0].type != ARRAY_OBJ
        return Error.new(
          "argument to 'first' must be Array, got=#{args[0]}.type"
        )
      end

      arr = args[0]

      return arr[0] if arr.length > 0

      nil
    }
  )

$builtins['last'] =
  Builtin.new(
    lambda { |*args|
      if args.length != 1
        return Error.new(
          "wrong number of arguments. got=#{args.length}, want=1"
        )
      end

      if args[0].type != ARRAY_OBJ
        return Error.new(
          "argument to 'last' must be Array, got=#{args[0]}.type"
        )
      end

      arr = args[0]

      return arr[-1] if arr.length > 0

      nil
    }
  )

$builtins['rest'] =
  Builtin.new(
    lambda { |*args|
      if args.length != 1
        return Error.new(
          "wrong number of arguments. got=#{args.length}, want=1"
        )
      end

      if args[0].type != ARRAY_OBJ
        return Error.new(
          "argument to 'rest' must be Array, got=#{args[0]}.type"
        )
      end

      arr = args[0]

      return arr[1..-1] if arr.length > 0

      nil
    }
  )

$builtins['push'] =
  Builtin.new(
    lambda { |*args|
      if args.length != 2
        return Error.new(
          "wrong number of arguments. got=#{args.length}, want=2"
        )
      end

      if args[0].type != ARRAY_OBJ
        return Error.new(
          "argument to 'push' must be Array, got=#{args[0]}.type"
        )
      end

      arr = args[0]

      return arr.append(args[1]) if arr.length > 0

      nil
    }
  )
