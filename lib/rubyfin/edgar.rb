require "rubyfin"

module Rubyfin::Edgar
  class Error < StandardError; end
  class MissingUserAgent < Error; end
  class RateLimited < Error; end
  class NotFound < Error; end

  def self.source
    Rubyfin::Source.new(
      "edgar",
      "SEC EDGAR",
      "https://www.sec.gov/edgar",
      {
        adapter: "rubyfin-edgar",
        rubyfin_version: Rubyfin::VERSION,
        edgar_version: VERSION
      }
    )
  end

  def self.database(**options)
    Database.new(client: Client.new(**options))
  end

  def self.company(identifier, **options)
    database(**options).company(identifier)
  end
end

require_relative "edgar/version"
require_relative "edgar/client"
require_relative "edgar/company_tickers"
require_relative "edgar/eight_k_item"
require_relative "edgar/submissions"
require_relative "edgar/database"
require_relative "edgar/company"
require_relative "edgar/filing_collection"
require_relative "edgar/filing"
require_relative "edgar/filing_item"
require_relative "edgar/document"
require_relative "edgar/company_facts"
require_relative "edgar/rate_limiter"
