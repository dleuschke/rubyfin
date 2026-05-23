require "rubyfin"

module Rubyfin::WorldBank
  class Error < StandardError; end
  class NotFound < Error; end

  API_DOCS_URL = "https://datahelpdesk.worldbank.org/knowledgebase/articles/889392"
  TERMS_URL = "https://datacatalog.worldbank.org/all-licenses"

  def self.source
    Rubyfin::Source.new(
      "world_bank",
      "World Bank",
      "https://data.worldbank.org",
      {
        adapter: "rubyfin-world-bank",
        api_docs_url: API_DOCS_URL,
        terms_url: TERMS_URL,
        rubyfin_version: Rubyfin::VERSION
      }
    )
  end

  def self.client(**options)
    Client.new(**options)
  end

  def self.indicator(indicator_id, **options)
    client(**options).indicator(indicator_id)
  end

  def self.observations(country, indicator_id, date: nil, per_page: nil, **options)
    request_options = {}
    request_options[:date] = date if date
    request_options[:per_page] = per_page if per_page

    client(**options).observations(country, indicator_id, **request_options)
  end
end

require_relative "world_bank/client"
require_relative "world_bank/indicator"
require_relative "world_bank/observation"
