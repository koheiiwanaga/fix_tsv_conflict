module FixTSVConflict
  class Conflict
    attr_reader :left, :lbranch, :right, :rbranch

    def initialize(left, lbranch, right, rbranch)
      @left = merge_multiline(left)
      @lbranch = lbranch
      @right = merge_multiline(right)
      @rbranch = rbranch
    end

    def merge_multiline(text)
      _prev_line = nil
      _text      = []
      text.each do |line|
        if line.scan(QUOTE).size.odd?
          if _prev_line.nil?
            _prev_line = line
          else
            _prev_line += line
            _text << _prev_line
            _prev_line = nil
          end
        else
          if _prev_line.nil?
            _text << line
          else
            _prev_line += line
          end
        end
      end
      _text
    end

    ID_REGEXP = /\A[0-9]+\t/
    NL_REGEXP = /\A\n/

    def valid?
      left.all? { |line| ID_REGEXP =~ line || NL_REGEXP =~ line} &&
        right.all? { |line| ID_REGEXP =~ line || NL_REGEXP =~ line }
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
  end
end
