require "json"
require "net/http"
require "uri"

module Rubyfin::OpenFigi
  class Client
    DEFAULT_BASE_URL = "https://api.openfigi.com/v3"

    class NetHttpClient
      def initialize(open_timeout:, read_timeout:)
        @open_timeout = open_timeout
        @read_timeout = read_timeout
      end

      def post_json(uri, body:, headers:)
        request = Net::HTTP::Post.new(uri)
        headers.each { |key, value| request[key] = value }
        request.body = body

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
      api_key: ENV["OPENFIGI_API_KEY"],
      base_url: DEFAULT_BASE_URL,
      open_timeout: 5,
      read_timeout: 30,
      http_client: nil
    )
      @api_key = api_key.to_s.strip
      @base_uri = URI(base_url.to_s.delete_suffix("/"))
      @http_client = http_client || NetHttpClient.new(open_timeout:, read_timeout:)
    end

    def map(jobs)
      normalized_jobs = Array(jobs).map { |job| normalize_job(job) }
      raise ArgumentError, "At least one OpenFIGI mapping job is required" if normalized_jobs.empty?

      payload = request_json("/mapping", normalized_jobs)
      Array(payload).each_with_index.map do |result, index|
        MappingResult.new(job: normalized_jobs.fetch(index), payload: result)
      end
    end

    def map_ticker(ticker, **options)
      map([{ id_type: "TICKER", id_value: ticker }.merge(options)])
    end

    private

    def request_json(path, payload)
      uri = URI("#{@base_uri}#{path}")
      code, body = @http_client.post_json(
        uri,
        body: JSON.generate(payload),
        headers: request_headers
      )

      case code
      when 200
        JSON.parse(body.to_s.empty? ? "[]" : body)
      when 400, 404
        raise NotFound, "OpenFIGI request failed with HTTP #{code}: #{body.to_s[0, 500]}"
      else
        raise Error, "OpenFIGI request failed with HTTP #{code}: #{body.to_s[0, 500]}"
      end
    rescue JSON::ParserError => e
      raise Error, "OpenFIGI returned invalid JSON: #{e.message}"
    end

    def request_headers
      headers = {
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }
      headers["X-OPENFIGI-APIKEY"] = @api_key unless @api_key.empty?
      headers
    end

    def normalize_job(job)
      case job
      when Hash
        normalized = {}
        job.each { |key, value| normalized[normalize_key(key)] = value unless value.nil? }
        normalized
      else
        raise ArgumentError, "OpenFIGI mapping jobs must be Hash objects"
      end
    end

    def normalize_key(key)
      case key.to_s
      when "id_type", "idType"
        "idType"
      when "id_value", "idValue"
        "idValue"
      when "exch_code", "exchCode"
        "exchCode"
      when "mic_code", "micCode"
        "micCode"
      when "currency"
        "currency"
      when "market_sec_des", "marketSecDes"
        "marketSecDes"
      when "security_type", "securityType"
        "securityType"
      when "security_type2", "securityType2"
        "securityType2"
      when "include_unlisted_equities", "includeUnlistedEquities"
        "includeUnlistedEquities"
      when "option_type", "optionType"
        "optionType"
      when "strike"
        "strike"
      when "contract_size", "contractSize"
        "contractSize"
      when "coupon"
        "coupon"
      when "expiration"
        "expiration"
      when "maturity"
        "maturity"
      else
        key.to_s
      end
    end
  end
end
