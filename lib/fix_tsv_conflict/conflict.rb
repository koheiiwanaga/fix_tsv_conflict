require 'csv'
require "fix_tsv_conflict/refinements/tsv"
require "fix_tsv_conflict/refinements/colored_string"

module FixTSVConflict
  class Conflict
    using Refinements::TSV
    using Refinements::ColoredString

    attr_reader :left, :lbranch, :right, :rbranch, :before

    def initialize(left, lbranch, right, rbranch, before = [])
      @left = left
      @lbranch = lbranch
      @right = right
      @rbranch = rbranch
      @before = before
    end

    ID_REGEXP = /\A[0-9]+\t/
    NL_REGEXP = /\A\n/

    def valid?
      left.all? { |line| ID_REGEXP =~ line || NL_REGEXP =~ line} &&
        right.all? { |line| ID_REGEXP =~ line || NL_REGEXP =~ line }
    end

    def tsv_same_line?
      llines = CSV.parse((before + left).join.append_quote_if_missing, col_sep: TAB)
      rlines = CSV.parse((before + right).join.append_quote_if_missing, col_sep: TAB)
      llines.size == rlines.size && llines.size.times.all? {|i| llines[i].first.to_i == rlines[i].first.to_i }
    end

    def to_a
      result = []
      result << "#{LEFT} #{lbranch}\n"
      result += left
      result << "#{SEP}\n"
      result += right
      result << "#{RIGHT} #{rbranch}\n"
      result
    end

    def colored_to_a
      return to_a unless tsv_same_line?
      l, r, ls, rs = left.join, right.join, [], []
      lv, lseek = l.tsv_next
      rv, rseek = r.tsv_next
      while lv || rv
        modified = lv != rv
        ls << (modified && lv ? lv.red : lv)
        rs << (modified && rv ? rv.green : rv)
        lv, lseek = l.tsv_next(lseek)
        rv, rseek = r.tsv_next(rseek)
      end
      result = []
      result << "#{LEFT} #{lbranch}\n"
      result += [ls.join(TAB)]
      result << "#{SEP}\n"
      result += [rs.join(TAB)]
      result << "#{RIGHT} #{rbranch}\n"
      result
    end
  end
end
