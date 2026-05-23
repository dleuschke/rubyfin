require "rubyfin"

module Rubyfin::Oecd
  class Error < StandardError; end
  class NotFound < Error; end

  API_DOCS_URL = "https://www.oecd.org/en/data/insights/data-explainers/2024/09/api.html"
  API_BEST_PRACTICES_URL = "https://www.oecd.org/en/data/insights/data-explainers/2024/11/Api-best-practices-and-recommendations.html"
  TERMS_URL = "https://www.oecd.org/en/about/terms-conditions.html"

  def self.source
    Rubyfin::Source.new(
      "oecd",
      "OECD",
      "https://data-explorer.oecd.org",
      {
        adapter: "rubyfin-oecd",
        api_docs_url: API_DOCS_URL,
        api_best_practices_url: API_BEST_PRACTICES_URL,
        terms_url: TERMS_URL,
        rubyfin_version: Rubyfin::VERSION
      }
    )
  end

  def self.client(**options)
    Client.new(**options)
  end

  def self.data(dataflow, **options)
    client_options = options.slice(:base_url, :open_timeout, :read_timeout, :http_client)
    data_options = options.except(:base_url, :open_timeout, :read_timeout, :http_client)

    client(**client_options).data(dataflow, **data_options)
  end
end

require_relative "oecd/client"
require_relative "oecd/observation"
