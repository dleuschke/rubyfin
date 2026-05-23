require "csv"
require "date"
require "net/http"
require "uri"

module Rubyfin::Oecd
  class Client
    DEFAULT_BASE_URL = "https://sdmx.oecd.org/public/rest"
    CSV_FORMATS = {
      csvfile: "csvfile",
      csvfilewithlabels: "csvfilewithlabels"
    }.freeze

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

    def initialize(base_url: DEFAULT_BASE_URL, open_timeout: 5, read_timeout: 60, http_client: nil)
      @base_uri = URI(base_url.to_s.delete_suffix("/"))
      @http_client = http_client || NetHttpClient.new(open_timeout:, read_timeout:)
    end

    def data(
      dataflow,
      key: nil,
      start_period: nil,
      end_period: nil,
      first_n_observations: nil,
      last_n_observations: nil,
      format: :csvfile
    )
      body = request_csv(
        dataflow,
        key:,
        params: {
          format: normalize_format(format),
          startPeriod: start_period,
          endPeriod: end_period,
          firstNObservations: first_n_observations,
          lastNObservations: last_n_observations
        }.reject { |_name, value| value.nil? }
      )

      parse_observations(body, requested_dataflow: dataflow.to_s, requested_key: key.to_s)
    end

    private

    def request_csv(dataflow, key:, params:)
      uri = build_data_uri(dataflow, key:, params:)
      code, body = @http_client.get_text(
        uri,
        headers: { "Accept" => "text/csv,text/plain;q=0.9,*/*;q=0.8" }
      )

      case code
      when 200
        body
      when 400, 404
        raise NotFound, "OECD request failed with HTTP #{code}: #{body.to_s[0, 500]}"
      else
        raise Error, "OECD request failed with HTTP #{code}: #{body.to_s[0, 500]}"
      end
    end

    def build_data_uri(dataflow, key:, params:)
      path = [@base_uri.path, "data", dataflow.to_s.strip].reject(&:empty?).join("/")
      path = "#{path}/#{key.to_s.strip}" if key && !key.to_s.strip.empty?

      uri = @base_uri.dup
      uri.path = path
      uri.query = URI.encode_www_form(params)
      uri
    end

    def parse_observations(body, requested_dataflow:, requested_key:)
      text = body.to_s.strip
      raise NotFound, "OECD returned no data for #{requested_dataflow.inspect}" if text.empty?
      raise Error, "OECD returned an HTML response instead of CSV" if text.start_with?("<")

      csv = CSV.parse(text, headers: true)
      headers = Array(csv.headers)
      unless headers.include?("TIME_PERIOD") && headers.include?("OBS_VALUE")
        raise Error, "OECD returned unexpected CSV headers: #{headers.join(", ")}"
      end

      csv.map do |row|
        Observation.new(
          payload: row.to_h,
          requested_dataflow:,
          requested_key:,
          headers:
        )
      end
    rescue CSV::MalformedCSVError => e
      raise Error, "OECD returned invalid CSV: #{e.message}"
    end

    def normalize_format(format)
      CSV_FORMATS.fetch(format.to_sym) do
        raise Error, "Unsupported OECD CSV format #{format.inspect}. Use :csvfile or :csvfilewithlabels."
      end
    rescue NoMethodError
      raise Error, "Unsupported OECD CSV format #{format.inspect}. Use :csvfile or :csvfilewithlabels."
    end
  end
end
