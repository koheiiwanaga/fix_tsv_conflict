require "fix_tsv_conflict/logging"
require "fix_tsv_conflict/refinements/blank"

module FixTSVConflict
  class Resolver
    include Logging
    using Refinements::Blank

    attr_reader :stdin, :stderr
    attr_accessor :tabs

    def initialize(stdin: $stdin, stderr: $stderr)
      @stdin  = stdin
      @stderr = stderr

      @tabs = 0
    end

    def resolve(conflict)
      unless conflict.valid?
        return conflict.to_a
      end

      result = try(conflict)
      if result
        return result
      end

      warn "Failed to resolve it automatically."
      select(conflict)
    end

    def try(conflict)
      result = []
      left  = index_by_id(conflict.left.reject { |l| l.blank? })
      right = index_by_id(conflict.right.reject { |r| r.blank? })
      (left.keys + right.keys).uniq.sort_by { |k| [k.to_i, k] }.each do |id|
        l = left[id]
        r = right[id]
        if l && r
          if l.rstrip == r.rstrip
            result << pick_by_tabs(l, r)
          else
            return false
          end
        else
          result << (l || r)
        end
      end
      result
    end

    def select(conflict)
      text = <<-TEXT
Which branch do you want to keep?

  1) #{conflict.lbranch}
  2) #{conflict.rbranch}
  k) keep as is

      TEXT

      info text

      loop do
        info "Please enter 1, 2, or k: ", no_newline: true
        case selected = stdin.gets.strip
        when "1"
          return conflict.left
        when "2"
          return conflict.right
        when "k"
          return conflict.to_a
        else
          info "Invalid input: #{selected}"
        end
      end
    end

    def index_by_id(lines)
      result = {}
      lines.each do |line|
        id = line.split(TAB, 2).first
        result[id] = line
      end
      result
    end

    def pick_by_tabs(l, r)
      ltabs = l.count(TAB)
      rtabs = r.count(TAB)

      if ltabs == tabs
        l
      elsif rtabs == tabs
        r
      else
        # both are wrong.
        # so this is a determistic picking.
        ltabs < rtabs ? l : r
      end
    end
  end
end
