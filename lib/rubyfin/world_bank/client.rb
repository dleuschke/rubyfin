require "json"
require "net/http"
require "uri"

module Rubyfin::WorldBank
  class Client
    DEFAULT_BASE_URL = "https://api.worldbank.org/v2"
    DEFAULT_PER_PAGE = 20_000

    class NetHttpClient
      def initialize(open_timeout:, read_timeout:)
        @open_timeout = open_timeout
        @read_timeout = read_timeout
      end

      def get_json(uri, headers:)
        request = Net::HTTP::Get.new(uri)
        headers.each { |key, value| request[key] = value }

        response = Net::HTTP.start(
          uri.hostname,
          uri.port,
          use_ssl: uri.scheme == "https",
          open_timeout: @open_timeout,
          read_timeout: @read_timeout
        ) { |http| http.request(request) }

        [response.code.to_i, response.body.to_s]
      end
    end

    def initialize(base_url: DEFAULT_BASE_URL, open_timeout: 5, read_timeout: 30, http_client: nil)
      @base_uri = URI(base_url.to_s.delete_suffix("/"))
      @http_client = http_client || NetHttpClient.new(open_timeout:, read_timeout:)
    end

    def indicator(indicator_id)
      _metadata, records = request_json("/indicator/#{escape_path(indicator_id)}")
      data = Array(records).first
      raise NotFound, "World Bank indicator not found for #{indicator_id.inspect}" unless data

      Indicator.new(data)
    end

    def observations(country, indicator_id, date: nil, per_page: DEFAULT_PER_PAGE)
      path = "/country/#{country_path(country)}/indicator/#{escape_path(indicator_id)}"
      params = { per_page: per_page.to_i }
      params[:date] = format_date_query(date) if date

      _metadata, records = request_all_pages(path, params)
      Array(records).map { |data| Observation.new(data) }
    end

    private

    def request_all_pages(path, params)
      metadata, records = request_json(path, **params, page: 1)
      pages = Integer(metadata.fetch("pages", 1))
      all_records = Array(records)

      (2..pages).each do |page|
        _page_metadata, page_records = request_json(path, **params, page:)
        all_records.concat(Array(page_records))
      end

      [metadata, all_records]
    rescue ArgumentError, TypeError
      raise Error, "World Bank returned invalid pagination metadata"
    end

    def request_json(path, **params)
      uri = build_uri(path, params)
      code, body = @http_client.get_json(uri, headers: { "Accept" => "application/json" })

      case code
      when 200
        payload = JSON.parse(body.to_s.empty? ? "[]" : body)
        raise Error, "World Bank returned unexpected JSON shape" unless payload.is_a?(Array)

        error = payload.find { |entry| entry.is_a?(Hash) && entry["message"] }
        raise NotFound, "World Bank request failed: #{format_error_message(error)}" if error

        [payload[0] || {}, payload[1] || []]
      when 400, 404
        raise NotFound, "World Bank request failed with HTTP #{code}: #{body.to_s.first(500)}"
      else
        raise Error, "World Bank request failed with HTTP #{code}: #{body.to_s.first(500)}"
      end
    rescue JSON::ParserError => e
      raise Error, "World Bank returned invalid JSON: #{e.message}"
    end

    def build_uri(path, params)
      query = { format: "json" }.merge(params)
      uri = URI("#{@base_uri}#{path}")
      uri.query = URI.encode_www_form(query)
      uri
    end

    def country_path(country)
      values = Array(country).flat_map { |value| value.to_s.split(";") }
      normalized = values.map { |value| value.strip.downcase }.reject(&:empty?)
      normalized.empty? ? "all" : normalized.join(";")
    end

    def escape_path(value)
      URI.encode_www_form_component(value.to_s.strip)
    end

    def format_date_query(value)
      case value
      when Range
        "#{format_date_part(value.begin)}:#{format_date_part(value.end)}"
      when Array
        value.map { |part| format_date_part(part) }.join(":")
      else
        value.to_s
      end
    end

    def format_date_part(value)
      return value.strftime("%Y") if value.respond_to?(:strftime)

      value.to_s
    end

    def format_error_message(error)
      Array(error&.fetch("message", nil)).map { |message| message["value"] || message.inspect }.join("; ")
    end
  end
end
