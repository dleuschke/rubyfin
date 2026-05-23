require "rubyfin"

module Rubyfin::Stooq
  class Error < StandardError; end
  class MissingApiKey < Error; end
  class NotFound < Error; end
  class InvalidInterval < Error; end

  TERMS_URL = "https://stooq.com/terms.html"
  HISTORICAL_DATA_URL = "https://stooq.com/db/h/"

  def self.source
    Rubyfin::Source.new(
      "stooq",
      "Stooq",
      "https://stooq.com",
      {
        adapter: "rubyfin-stooq",
        api_key_env: "STOOQ_API_KEY",
        terms_url: TERMS_URL,
        historical_data_url: HISTORICAL_DATA_URL,
        rubyfin_version: Rubyfin::VERSION
      }
    )
  end

  def self.client(**options)
    Client.new(**options)
  end

  def self.prices(symbol, start_date: nil, end_date: nil, interval: :daily, **options)
    client(**options).prices(symbol, start_date:, end_date:, interval:)
  end
end

require_relative "stooq/client"
require_relative "stooq/price_bar"
