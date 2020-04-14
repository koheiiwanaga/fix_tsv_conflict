require "fix_tsv_conflict/conflict"
require "fix_tsv_conflict/logging"
require "fix_tsv_conflict/resolver"
require "fix_tsv_conflict/refinements/tsv"

module FixTSVConflict
  class Repairman
    include Logging
    using Refinements::TSV

    attr_reader :stdin, :stderr

    def initialize(stdin: $stdin, stderr: $stderr)
      @stdin  = stdin
      @stderr = stderr
    end

    def resolver
      @resolver ||= Resolver.new(stdin: stdin, stderr: stderr)
    end

    def repair(source)
      result = []
      branch = nil
      left,  lbranch = [], nil
      right, rbranch = [], nil

      source.each_line.with_index do |line, i|
        if i.zero?
          load_header(line)
          result << line
        elsif line.start_with?(LEFT)
          lbranch = line.chomp.split(" ").last
          branch = left
        elsif line.start_with?(SEP)
          branch = right
        elsif line.start_with?(RIGHT)
          rbranch = line.chomp.split(" ").last
          result += handle(left, lbranch, right, rbranch, tsv_before(left.join, result.dup))
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

    def load_header(header)
      resolver.header = header
    end

    def handle(left, lbranch, right, rbranch, before)
      conflict = Conflict.new(left, lbranch, right, rbranch, before)
      print_conflict(conflict)
      result = resolver.resolve(conflict)
      print_result(result)
      result
    end

    def print_conflict(conflict)
      info "Found a conflict:"
      blank
      dump conflict.colored_to_a
      blank
    end

    def print_result(result)
      notice "Resolved to:"
      blank
      dump result
      blank
      blank
    end

    def tsv_before(str, lines, before = [])
      if str.start_within_quote?
        before.unshift(line = lines.pop)
        tsv_before(line + str, lines, before)
      end
      before
    end
  end
end
