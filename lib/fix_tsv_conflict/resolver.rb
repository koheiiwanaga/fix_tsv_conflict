require "fix_tsv_conflict/logging"
require "fix_tsv_conflict/refinements/blank"
require "fix_tsv_conflict/refinements/tsv"

module FixTSVConflict
  class Resolver
    include Logging
    using Refinements::Blank
    using Refinements::TSV

    attr_reader :stdin, :stderr
    attr_accessor :header

    def initialize(stdin: $stdin, stderr: $stderr)
      @stdin  = stdin
      @stderr = stderr
    end

    def resolve(conflict)
      unless conflict.valid?
        if conflict.tsv_same_line?
          return tsv_merge(conflict)
        else
          return conflict.to_a
        end
      end

      result = try(conflict)
      if result
        return result
      end

      warn "Failed to resolve it automatically."
      select(conflict)
    end

    def tsv_merge(conflict)
      org_headers = CSV.parse(header, col_sep: TAB).first
      headers, before = org_headers.dup, conflict.before.join
      if before.end_within_quote?
        before += QUOTE
        headers.slice!(0, CSV.parse(before, col_sep: TAB).first.size - 1)
      elsif !before.blank?
        headers.slice!(0, CSV.parse(before, col_sep: TAB).first.size)
      end
      result, left, right = [], conflict.left.join, conflict.right.join
      lvalue, lseek = left.tsv_next
      rvalue, rseek = right.tsv_next
      while lvalue || rvalue
        column = headers.shift
        if !column && (lvalue || rvalue).end_with?(LF) #end of line
          headers = org_headers.dup
        end
        if lvalue != rvalue
          if selected = select_column(conflict, column, lvalue, rvalue)
            result << selected
          else
            return conflict.to_a
          end
        else
          result << lvalue
        end
        lvalue, lseek = left.tsv_next(lseek)
        rvalue, rseek = right.tsv_next(rseek)
      end
      [result.join(TAB)]
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
      tsv_mergeable = conflict.tsv_same_line?
      text = <<-TEXT
Which branch do you want to keep?

  1) #{conflict.lbranch}
  2) #{conflict.rbranch}
  k) keep as is#{tsv_mergeable ? "\n  t) tsv merge mode" : ''}

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
        when "t"
          if tsv_mergeable
            return tsv_merge(conflict)
          else
            info "Invalid input: #{selected}"
          end
        else
          info "Invalid input: #{selected}"
        end
      end
    end

    def select_column(conflict, column, lvalue, rvalue)
      text = <<-TEXT
Which branch do you want to keep for #{column}?

  1) #{conflict.lbranch}: #{lvalue}
  2) #{conflict.rbranch}: #{rvalue}
  k) keep this conflict

      TEXT

      info text

      loop do
        info "Please enter 1, 2, or s: ", no_newline: true
        case selected = stdin.gets.strip
          when "1"
            return lvalue
          when "2"
            return rvalue
          when "k"
            return false
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

    def tabs
      @tabs ||= (header || raise('header is not initialized.')).count(TAB)
    end
  end
end
