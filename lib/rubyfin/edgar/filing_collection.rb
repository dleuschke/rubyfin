module Rubyfin::Edgar
  class FilingCollection
    include Enumerable

    def initialize(company:, client:, forms: nil, since: nil)
      @company = company
      @client = client
      @forms = Array(forms).compact.map(&:to_s)
      @since = since
    end

    def each(&block)
      filings.each(&block)
    end

    def form(value)
      forms(value)
    end

    def forms(*values)
      flattened = values.flatten.compact.map(&:to_s)
      self.class.new(company: @company, client: @client, forms: flattened, since: @since)
    end

    def since(value)
      self.class.new(company: @company, client: @client, forms: @forms, since: value)
    end

    def latest
      filings.first
    end

    def accession(value)
      filings.find { |filing| filing.accession == value.to_s }
    end

    def to_a
      filings
    end

    private

    def filings
      @filings ||= begin
        records = Submissions.recent_filings(
          @client.submissions(@company.cik),
          cik: @company.cik,
          forms: @forms,
          since: @since
        )
        records.map { |record| Filing.new(company: @company, record:, client: @client) }
      end
    end
  end
end
