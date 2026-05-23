require "date"
require "time"

module Rubyfin::Edgar
  class Submissions
    FilingRecord = Data.define(
      :cik,
      :company_name,
      :accession,
      :form,
      :filed_at,
      :item_codes,
      :primary_document
    )

    FilingItem = Data.define(
      :cik,
      :company_name,
      :accession,
      :form,
      :filed_at,
      :item_code,
      :primary_document
    )

    def self.recent_items(payload, cik:, forms: [], since: nil)
      new(payload, cik:, forms:, since:).recent_items
    end

    def self.recent_filings(payload, cik:, forms: [], since: nil)
      new(payload, cik:, forms:, since:).recent_filings
    end

    def initialize(payload, cik:, forms: [], since: nil)
      @payload = payload || {}
      @cik = cik
      @forms = Array(forms).map(&:to_s)
      @since = normalize_time(since)
    end

    def recent_items
      recent_filings.flat_map do |filing|
        filing.item_codes.map do |item_code|
          FilingItem.new(
            filing.cik,
            filing.company_name,
            filing.accession,
            filing.form,
            filing.filed_at,
            item_code,
            filing.primary_document
          )
        end
      end
    end

    def recent_filings
      recent = @payload.dig("filings", "recent") || {}
      Array(recent["accessionNumber"]).each_index.filter_map do |index|
        filing_record(recent, index)
      end.compact
    end

    private

    def filing_record(recent, index)
      form = value(recent, "form", index).to_s
      return if @forms.any? && !@forms.include?(form)

      accession = value(recent, "accessionNumber", index).to_s.strip
      return if accession.empty?

      filed_at = parse_filed_at(value(recent, "acceptanceDateTime", index)) ||
        parse_filed_at(value(recent, "filingDate", index))
      return if filed_at.nil?
      return if @since && filed_at < @since

      primary_document = value(recent, "primaryDocument", index).to_s.strip
      FilingRecord.new(
        @cik,
        company_name,
        accession,
        form,
        filed_at,
        items_for(value(recent, "items", index)),
        primary_document.empty? ? nil : primary_document
      )
    end

    def company_name
      @payload["name"].to_s.strip.empty? ? nil : @payload["name"].to_s.strip
    end

    def items_for(raw_value)
      codes = raw_value.to_s.scan(/\d+\.\d{2}/).uniq
      codes.empty? ? ["?"] : codes
    end

    def value(recent, key, index)
      Array(recent[key])[index]
    end

    def parse_filed_at(value)
      text = value.to_s.strip
      return if text.empty?

      if text.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        date = Date.iso8601(text)
        Time.utc(date.year, date.month, date.day)
      else
        Time.iso8601(text)
      end
    rescue ArgumentError
      nil
    end

    def normalize_time(value)
      return if value.nil?
      return value.to_time if value.respond_to?(:to_time)
      return Time.utc(value.year, value.month, value.day) if value.respond_to?(:year) && value.respond_to?(:month) && value.respond_to?(:day)

      Time.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
