require "csv"
require "date"
require "net/http"
require "uri"

module Rubyfin::Stooq
  class Client
    DEFAULT_BASE_URL = "https://stooq.com/q/d/l/"
    INTERVAL_CODES = {
      "d" => "daily",
      "daily" => "daily",
      "w" => "weekly",
      "weekly" => "weekly",
      "m" => "monthly",
      "monthly" => "monthly",
      "q" => "quarterly",
      "quarterly" => "quarterly",
      "y" => "yearly",
      "yearly" => "yearly"
    }.freeze
    INTERVAL_QUERY_CODES = {
      "daily" => "d",
      "weekly" => "w",
      "monthly" => "m",
      "quarterly" => "q",
      "yearly" => "y"
    }.freeze
    REQUIRED_HEADERS = ["Date", "Open", "High", "Low", "Close", "Volume"].freeze

    class NetHttpClient
      def initialize(open_timeout:, read_timeout:)
        @open_timeout = open_timeout
        @read_timeout = read_timeout
      end

      def get_text(uri, headers:)
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
      api_key: ENV["STOOQ_API_KEY"],
      base_url: DEFAULT_BASE_URL,
      open_timeout: 5,
      read_timeout: 30,
      http_client: nil
    )
      @api_key = api_key.to_s.strip
      @base_uri = URI(base_url.to_s)
      @http_client = http_client || NetHttpClient.new(open_timeout:, read_timeout:)
    end

    def prices(symbol, start_date: nil, end_date: nil, interval: :daily)
      ensure_api_key!
      normalized_interval = normalize_interval(interval)
      params = {
        s: normalize_symbol(symbol),
        i: INTERVAL_QUERY_CODES.fetch(normalized_interval),
        d1: format_date(start_date),
        d2: format_date(end_date),
        apikey: @api_key
      }.reject { |_key, value| value.nil? }

      body = request_csv(params)
      parse_price_bars(body, symbol: normalize_symbol(symbol), interval: normalized_interval)
    end

    private

    def request_csv(params)
      uri = build_uri(params)
      code, body = @http_client.get_text(
        uri,
        headers: { "Accept" => "text/csv,text/plain;q=0.9,*/*;q=0.8" }
      )

      case code
      when 200
        body
      when 400, 404
        raise NotFound, "Stooq request failed with HTTP #{code}: #{body.to_s.first(500)}"
      else
        raise Error, "Stooq request failed with HTTP #{code}: #{body.to_s.first(500)}"
      end
    end

    def build_uri(params)
      uri = @base_uri.dup
      uri.query = URI.encode_www_form(params)
      uri
    end

    def parse_price_bars(body, symbol:, interval:)
      text = body.to_s.strip
      raise MissingApiKey, "STOOQ_API_KEY is required for Stooq CSV downloads" if text.match?(/\AGet your apikey:/i)
      raise NotFound, "Stooq returned no data for #{symbol.inspect}" if text.empty? || text.match?(/\ANo data/i)

      csv = CSV.parse(text, headers: true)
      headers = Array(csv.headers)
      missing_headers = REQUIRED_HEADERS - headers
      unless missing_headers.empty?
        raise NotFound, "Stooq returned no price data for #{symbol.inspect}" if headers.one? && headers.first.to_s.match?(/no data/i)

        raise Error, "Stooq returned unexpected CSV headers: #{headers.join(", ")}"
      end

      csv.map { |row| PriceBar.new(symbol:, interval:, payload: row.to_h) }
    rescue CSV::MalformedCSVError => e
      raise Error, "Stooq returned invalid CSV: #{e.message}"
    end

    def normalize_symbol(symbol)
      symbol.to_s.strip.downcase
    end

    def normalize_interval(interval)
      value = interval.to_s.strip.downcase
      INTERVAL_CODES.fetch(value) do
        raise InvalidInterval, "Unsupported Stooq interval #{interval.inspect}. Use :daily, :weekly, :monthly, :quarterly, or :yearly."
      end
    end

    def format_date(value)
      return if value.nil?
      return value.strftime("%Y%m%d") if value.respond_to?(:strftime)

      text = value.to_s.strip
      return text if text.match?(/\A\d{8}\z/)

      Date.parse(text).strftime("%Y%m%d")
    end

    def ensure_api_key!
      return unless @api_key.empty?

      raise MissingApiKey, "STOOQ_API_KEY is required for Stooq CSV downloads"
    end
  end
end
