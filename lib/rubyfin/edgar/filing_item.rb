module Rubyfin::Edgar
  class FilingItem
    attr_reader :code, :filing

    def initialize(code:, filing:)
      @code = code.to_s
      @filing = filing
    end

    alias item_code code

    def label
      EightKItem.label(code)
    end

    def company
      filing.company
    end

    def accession
      filing.accession
    end

    def form
      filing.form
    end

    def filed_at
      filing.filed_at
    end

    def natural_key
      [company.cik, accession, code]
    end

    def to_h
      {
        cik: company.cik,
        ticker: company.ticker,
        accession:,
        form:,
        filed_at:,
        code:,
        label:
      }
    end

    def inspect
      "#<#{self.class.name} code=#{code.inspect} label=#{label.inspect} accession=#{accession.inspect}>"
    end
  end
end
