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

    def resolver
      @resolver ||= Resolver.new(stdin: stdin, stderr: stderr)
    end

    def repair(source)
      result = []
      branch = nil
      left,  lbranch = [], nil
      right, rbranch = [], nil
      merged_line,  _merged_line = nil, nil
      lmerged_line, rmerged_line = nil, nil

      source_lines = source.each_line.to_a
      source_lines.each_with_index do |line, i|
        if i.zero?
          load_tabs_count(line)
          result << line
        elsif line.start_with?(LEFT)
          lbranch = line.chomp.split(" ").last
          branch = left
          _merged_line = merged_line
        elsif line.start_with?(SEP)
          lmerged_line = merged_line
          branch = right
          merged_line = _merged_line
        elsif line.start_with?(RIGHT)
          rmerged_line = merged_line
          if lmerged_line && rmerged_line
            while (next_line = source_lines[i += 1])
              lmerged_line += next_line
              rmerged_line += next_line
              source_lines.delete_at(i)
              break if next_line.scan(QUOTE).size.odd?
            end
            left  << lmerged_line
            right << rmerged_line
            lmerged_line = nil
            rmerged_line = nil
          end
          rbranch = line.chomp.split(" ").last
          result += handle(left, lbranch, right, rbranch)
          branch = nil
          left.clear
          right.clear
        else
          if branch
            if line.scan(QUOTE).size.odd?
              if merged_line.nil?
                merged_line = line
              else
                merged_line += line
                branch << merged_line
                merged_line = nil
              end
            else
              if merged_line.nil?
                branch << line
              else
                merged_line += line
              end
            end
          else
            if line.scan(QUOTE).size.odd?
              if merged_line.nil?
                merged_line = line
              else
                merged_line += line
                result << merged_line
                merged_line = nil
              end
            else
              if merged_line.nil?
                result << line
              else
                merged_line += line
              end
            end
          end
        end
      end
      result.join
    end

    def load_tabs_count(header)
      resolver.tabs = header.count(TAB)
    end

    def handle(left, lbranch, right, rbranch)
      conflict = Conflict.new(left, lbranch, right, rbranch)
      print_conflict(conflict)
      result = resolver.resolve(conflict)
      print_result(result)
      result
    end

    def print_conflict(conflict)
      info "Found a conflict:"
      blank
      dump conflict.to_a
      blank
    end

    def print_result(result)
      notice "Resolved to:"
      blank
      dump result
      blank
      blank
    end
  end
end
