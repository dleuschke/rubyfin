require "rubyfin"

module Rubyfin::Fred
  class Error < StandardError; end
  class MissingApiKey < Error; end
  class NotFound < Error; end

  def self.source
    Rubyfin::Source.new(
      "fred",
      "FRED",
      "https://fred.stlouisfed.org",
      {
        adapter: "rubyfin-fred",
        rubyfin_version: Rubyfin::VERSION
      }
    )
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
