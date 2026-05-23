require "json"
require "net/http"
require "uri"

module Rubyfin::Edgar
  class Client
    DEFAULT_COMPANY_TICKERS_URL = "https://www.sec.gov/files/company_tickers.json"
    DEFAULT_DATA_BASE_URL = "https://data.sec.gov"
    DEFAULT_SUBMISSIONS_BASE_PATH = "/submissions"
    DEFAULT_ARCHIVES_BASE_URL = "https://www.sec.gov/Archives/edgar/data"

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
      user_agent:,
      company_tickers_url: DEFAULT_COMPANY_TICKERS_URL,
      data_base_url: DEFAULT_DATA_BASE_URL,
      submissions_base_url: nil,
      archives_base_url: DEFAULT_ARCHIVES_BASE_URL,
      open_timeout: 5,
      read_timeout: 30,
      http_client: nil
    )
      @user_agent = user_agent.to_s.strip
      @company_tickers_uri = URI(company_tickers_url)
      @data_base_uri = URI(data_base_url.to_s.delete_suffix("/"))
      @submissions_base_uri = URI((submissions_base_url || "#{@data_base_uri}#{DEFAULT_SUBMISSIONS_BASE_PATH}").to_s.delete_suffix("/"))
      @archives_base_uri = URI(archives_base_url.to_s.delete_suffix("/"))
      @http_client = http_client || NetHttpClient.new(open_timeout:, read_timeout:)
    end

    def company_tickers
      request_json(@company_tickers_uri)
    end

    def submissions(cik)
      request_json(submissions_uri(cik))
    end

    def company_facts(cik)
      request_json(data_uri("/api/xbrl/companyfacts/CIK#{padded_cik(cik)}.json"))
    end

    def company_concept(cik:, taxonomy:, tag:)
      request_json(data_uri("/api/xbrl/companyconcept/CIK#{padded_cik(cik)}/#{taxonomy}/#{tag}.json"))
    end

    def frames(taxonomy:, tag:, unit:, period:)
      request_json(data_uri("/api/xbrl/frames/#{taxonomy}/#{tag}/#{unit}/#{period}.json"))
    end

    def submissions_uri(cik)
      URI("#{@submissions_base_uri}/CIK#{padded_cik(cik)}.json")
    end

    def filing_index_url(cik:, accession:)
      "#{archive_base(cik, accession)}/#{accession}-index.htm"
    end

    def primary_document_url(cik:, accession:, document:)
      return if document.to_s.strip.empty?

      "#{archive_base(cik, accession)}/#{document}"
    end

    private

    def request_json(uri)
      ensure_user_agent!
      code, body = @http_client.get_json(
        uri,
        headers: {
          "Accept" => "application/json",
          "User-Agent" => @user_agent
        }
      )

      case code
      when 200
        JSON.parse(body.to_s.empty? ? "{}" : body)
      when 429
        raise RateLimited, "SEC EDGAR rate limit reached"
      else
        raise Error, "SEC EDGAR request failed with HTTP #{code}: #{body.to_s.first(500)}"
      end
    rescue JSON::ParserError => e
      raise Error, "SEC EDGAR returned invalid JSON: #{e.message}"
    end

    def data_uri(path)
      URI("#{@data_base_uri}#{path}")
    end

    def archive_base(cik, accession)
      "#{@archives_base_uri}/#{cik.to_i}/#{accession.to_s.delete("-")}"
    end

    def padded_cik(cik)
      cik.to_i.to_s.rjust(10, "0")
    end

    def ensure_user_agent!
      return unless @user_agent.empty?

      raise MissingUserAgent, "EDGAR_USER_AGENT is required for SEC EDGAR requests"
    end
  end
end
