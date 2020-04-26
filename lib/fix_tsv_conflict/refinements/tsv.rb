module FixTSVConflict
  module Refinements
    module TSV
      refine String do
        def start_within_quote?(pos = 0)
          first_end_quote = index("#{QUOTE}#{TAB}", pos) || index("#{QUOTE}#{LF}", pos)
          first_start_quote = index("#{TAB}#{QUOTE}", pos)
          first_end_quote && (!first_start_quote || first_end_quote < first_start_quote)
        end

        def end_within_quote?
          last_start_quote = rindex("#{TAB}#{QUOTE}")
          last_end_quote = rindex("#{QUOTE}#{LF}") || rindex("#{QUOTE}#{TAB}")
          last_start_quote && (!last_end_quote || last_end_quote < last_start_quote)
        end

        def append_quote_if_missing
          end_within_quote? ? self + QUOTE : self
        end

        def tsv_next(pos = 0)
          if start_within_quote?(pos)
            seek = index("#{QUOTE}#{TAB}", pos) || index("#{QUOTE}#{LF}", pos)
            return self[pos..seek], seek + 2
          else
            seek = (index(TAB, pos) || size) - 1
            return self[pos..seek], seek + 2
          end
        end
      end
    end
  end
end
