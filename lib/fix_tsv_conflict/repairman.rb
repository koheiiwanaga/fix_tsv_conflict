require "fix_tsv_conflict/conflict"
require "fix_tsv_conflict/logging"
require "fix_tsv_conflict/resolver"

module FixTSVConflict
  class Repairman
    include Logging

    attr_reader :stdin, :stderr

    def initialize(stdin: $stdin, stderr: $stderr)
      @stdin  = stdin
      @stderr = stderr
    end

    def repair(source)
      result = []
      branch = nil
      left,  lbranch = [], nil
      right, rbranch = [], nil

      source.each_line do |line|
        if line.start_with?(LEFT)
          lbranch = line.chomp.split(" ").last
          branch = left
        elsif line.start_with?(SEP)
          branch = right
        elsif line.start_with?(RIGHT)
          rbranch = line.chomp.split(" ").last
          result += handle(left, lbranch, right, rbranch)
          branch = nil
          left.clear
          right.clear
        else
          if branch
            branch << line
          else
            result << line
          end
        end
      end
      result.join
    end

    def handle(left, lbranch, right, rbranch)
      conflict = Conflict.new(left, lbranch, right, rbranch)
      print_conflict(conflict)
      result = resolve_conflict(conflict)
      print_result(result)
      result
    end

    def print_conflict(conflict)
      warn "A conflict found:"
      blank
      dump conflict.to_a
      blank
    end

    def print_result(result)
      notice "The conflict was fixed to:"
      blank
      dump result
      blank
      blank
    end

    def resolve_conflict(conflict)
      Resolver.new(stdin: stdin, stderr: stderr).resolve(conflict)
    end
  end
end
