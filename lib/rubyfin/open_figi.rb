require "rubyfin"

module Rubyfin::OpenFigi
  class Error < StandardError; end
  class NotFound < Error; end

  API_DOCS_URL = "https://www.openfigi.com/api/documentation"
  TERMS_URL = "https://www.openfigi.com/docs/terms-of-service"

  def self.source
    Rubyfin::Source.new(
      "open_figi",
      "OpenFIGI",
      "https://www.openfigi.com",
      {
        adapter: "rubyfin-open-figi",
        api_docs_url: API_DOCS_URL,
        terms_url: TERMS_URL,
        api_key_env: "OPENFIGI_API_KEY",
        rubyfin_version: Rubyfin::VERSION
      }
    )
  end

  def self.client(**options)
    Client.new(**options)
  end

  def self.map(jobs, **options)
    client_options = {}
    [:api_key, :base_url, :open_timeout, :read_timeout, :http_client].each do |key|
      client_options[key] = options.delete(key) if options.key?(key)
    end

    raise ArgumentError, "Unexpected OpenFIGI options: #{options.keys.join(", ")}" unless options.empty?

    client(**client_options).map(jobs)
  end

  def self.map_ticker(ticker, **options)
    client_options = {}
    [:api_key, :base_url, :open_timeout, :read_timeout, :http_client].each do |key|
      client_options[key] = options.delete(key) if options.key?(key)
    end

    client(**client_options).map_ticker(ticker, **options)
  end
end

require_relative "open_figi/client"
require_relative "open_figi/instrument"
require_relative "open_figi/mapping_result"
