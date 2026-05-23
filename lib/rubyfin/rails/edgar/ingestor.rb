require "time"

module Rubyfin::Rails::Edgar
    class Ingestor
      Result = Data.define(:run, :company, :counts)

      def initialize(user_agent: nil, database: nil, client_options: {}, clock: -> { Time.now.utc })
        @database = database || ::Rubyfin::Edgar.database(user_agent:, **client_options)
        @clock = clock
      end

      def ingest_company(identifier, forms: [], since: nil, include_facts: false)
        run = IngestionRun.create!(
          started_at: now,
          status: "running",
          scope: "company",
          options: run_options(identifier:, forms:, since:, include_facts:)
        )
        counts = empty_counts

        company = nil
        ApplicationRecord.transaction do
          edgar_company = @database.company(identifier)
          company = persist_company(edgar_company)
          counts["companies"] += 1

          edgar_company.filings.forms(forms).since(since).each do |filing|
            persisted_filing = persist_filing(company, filing)
            counts["filings"] += 1

            filing.items.each do |item|
              persist_filing_item(persisted_filing, item)
              counts["filing_items"] += 1
            end
          end

          counts["company_facts"] = persist_company_facts(company, edgar_company.facts) if include_facts
        end

        run.update!(finished_at: now, status: "succeeded", counts:)
        Result.new(run, company, counts)
      rescue StandardError => e
        run&.update!(
          finished_at: now,
          status: "failed",
          error_class: e.class.name,
          error_message: e.message,
          counts: counts || empty_counts
        )
        raise
      end

      private

      def persist_company(edgar_company)
        Company.find_or_initialize_by(cik: edgar_company.cik).tap do |company|
          company.assign_attributes(
            ticker: edgar_company.ticker,
            name: edgar_company.name,
            last_seen_at: now
          )
          company.save!
        end
      end

      def persist_filing(company, filing)
        Filing.find_or_initialize_by(cik: filing.company.cik, accession: filing.accession).tap do |record|
          record.assign_attributes(
            company:,
            form: filing.form,
            filed_at: filing.filed_at,
            company_name: filing.company_name,
            primary_document_name: filing.primary_document_name,
            index_url: filing.index_url,
            primary_document_url: filing.primary_document_url
          )
          record.save!
        end
      end

      def persist_filing_item(filing, item)
        FilingItem.find_or_initialize_by(cik: item.company.cik, accession: item.accession, code: item.code).tap do |record|
          record.assign_attributes(
            filing:,
            label: item.label
          )
          record.save!
        end
      end

      def persist_company_facts(company, facts)
        count = 0
        facts.facts.each do |taxonomy, tags|
          next unless tags.respond_to?(:each)

          tags.each do |tag, payload|
            CompanyFact.find_or_initialize_by(cik: company.cik, taxonomy: taxonomy.to_s, tag: tag.to_s).tap do |record|
              record.assign_attributes(
                company:,
                payload:,
                fetched_at: now
              )
              record.save!
            end
            count += 1
          end
        end
        count
      end

      def empty_counts
        {
          "companies" => 0,
          "filings" => 0,
          "filing_items" => 0,
          "company_facts" => 0
        }
      end

      def run_options(identifier:, forms:, since:, include_facts:)
        {
          "identifier" => identifier.to_s,
          "forms" => Array(forms).flatten.compact.map(&:to_s),
          "since" => serialize_time(since),
          "include_facts" => include_facts ? true : false
        }
      end

      def serialize_time(value)
        return if value.nil?
        return value.utc.iso8601 if value.respond_to?(:utc)
        return Time.parse(value.to_s).utc.iso8601
      rescue ArgumentError, TypeError
        value.to_s
      end

      def now
        @clock.call
      end
    end
end
