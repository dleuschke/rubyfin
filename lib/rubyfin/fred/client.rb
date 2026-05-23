require "json"
require "net/http"
require "uri"

module Rubyfin::Fred
  class Client
    DEFAULT_BASE_URL = "https://api.stlouisfed.org/fred"

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

    def initialize(
      api_key: ENV["FRED_API_KEY"],
      base_url: DEFAULT_BASE_URL,
      open_timeout: 5,
      read_timeout: 30,
      http_client: nil
    )
      @api_key = api_key.to_s.strip
      @base_uri = URI(base_url.to_s.delete_suffix("/"))
      @http_client = http_client || NetHttpClient.new(open_timeout:, read_timeout:)
    end

    def series(series_id)
      payload = request_json("/series", series_id: series_id.to_s)
      data = Array(payload["seriess"]).first || Array(payload["series"]).first
      raise NotFound, "FRED series not found for #{series_id.inspect}" unless data

      Series.new(data, client: self)
    end

    def search(search_text, limit: nil, offset: nil)
      params = { search_text: search_text.to_s }
      params[:limit] = limit if limit
      params[:offset] = offset if offset

      payload = request_json("/series/search", **params)
      Array(payload["seriess"]).map { |data| Series.new(data, client: self) }
    end

    def observations(series_id, observation_start: nil, observation_end: nil, realtime_start: nil, realtime_end: nil)
      params = { series_id: series_id.to_s }
      params[:observation_start] = format_date(observation_start) if observation_start
      params[:observation_end] = format_date(observation_end) if observation_end
      params[:realtime_start] = format_date(realtime_start) if realtime_start
      params[:realtime_end] = format_date(realtime_end) if realtime_end

      payload = request_json("/series/observations", **params)
      Array(payload["observations"]).map { |data| Observation.new(series_id: series_id.to_s, payload: data) }
    end

    private

    def request_json(path, **params)
      ensure_api_key!
      uri = build_uri(path, params)
      code, body = @http_client.get_json(uri, headers: { "Accept" => "application/json" })

      case code
      when 200
        JSON.parse(body.to_s.empty? ? "{}" : body)
      when 400, 404
        raise NotFound, "FRED request failed with HTTP #{code}: #{body.to_s.first(500)}"
      else
        raise Error, "FRED request failed with HTTP #{code}: #{body.to_s.first(500)}"
      end
    rescue JSON::ParserError => e
      raise Error, "FRED returned invalid JSON: #{e.message}"
    end

    def build_uri(path, params)
      query = {
        api_key: @api_key,
        file_type: "json"
      }.merge(params)
      uri = URI("#{@base_uri}#{path}")
      uri.query = URI.encode_www_form(query)
      uri
    end

    def format_date(value)
      return value.strftime("%Y-%m-%d") if value.respond_to?(:strftime)

      value.to_s
    end

    def ensure_api_key!
      return unless @api_key.empty?

      raise MissingApiKey, "FRED_API_KEY is required for FRED requests"
    end
  end
end
