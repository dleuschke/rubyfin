require "rubyfin"

module Rubyfin::Fred
  class Error < StandardError; end
  class MissingApiKey < Error; end
  class NotFound < Error; end

  ATTRIBUTION_NOTICE = "This product uses the FRED® API but is not endorsed or certified by the Federal Reserve Bank of St. Louis."
  TERMS_URL = "https://fred.stlouisfed.org/docs/api/terms_of_use.html"

  def self.source
    Rubyfin::Source.new(
      "fred",
      "FRED",
      "https://fred.stlouisfed.org",
      {
        adapter: "rubyfin-fred",
        attribution_notice: ATTRIBUTION_NOTICE,
        terms_url: TERMS_URL,
        rubyfin_version: Rubyfin::VERSION
      }
    )
  end

  def self.attribution_notice
    ATTRIBUTION_NOTICE
  end

  def self.client(**options)
    Client.new(**options)
  end

  def self.series(series_id, **options)
    client(**options).series(series_id)
  end

  def self.search(search_text, **options)
    client(**options).search(search_text)
  end
end

require_relative "fred/client"
require_relative "fred/series"
require_relative "fred/observation"
