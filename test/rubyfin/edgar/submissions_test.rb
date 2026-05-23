require_relative "../../test_helper"
require "rubyfin/edgar"

module Rubyfin::Edgar
  class SubmissionsTest < Minitest::Test
    test "normalizes recent submission filings into filing items" do
      items = Submissions.recent_items(
        {
          "name" => "Apple Inc.",
          "filings" => {
            "recent" => {
              "accessionNumber" => ["0000320193-26-000001", "0000320193-26-000002", "0000320193-26-000003"],
              "acceptanceDateTime" => ["2026-05-22T21:04:00.000Z", "2026-05-22T22:00:00.000Z", "2026-05-01T22:00:00.000Z"],
              "filingDate" => ["2026-05-22", "2026-05-22", "2026-05-01"],
              "form" => ["8-K", "10-Q", "8-K"],
              "primaryDocument" => ["aapl-20260522.htm", "aapl-20260510.htm", "old-8k.htm"],
              "items" => ["2.02, 9.01", "", "1.05"]
            }
          }
        },
        cik: 320193,
        forms: ["8-K"],
        since: Time.utc(2026, 5, 20)
      )

      assert_equal 2, items.length
      assert_equal ["2.02", "9.01"], items.map(&:item_code)
      assert_equal 320193, items.first.cik
      assert_equal "Apple Inc.", items.first.company_name
      assert_equal "0000320193-26-000001", items.first.accession
      assert_equal "8-K", items.first.form
      assert_equal Time.utc(2026, 5, 22, 21, 4), items.first.filed_at
      assert_equal "aapl-20260522.htm", items.first.primary_document
    end

    test "keeps an unknown item placeholder when SEC omits parsed item codes" do
      items = Submissions.recent_items(
        {
          "filings" => {
            "recent" => {
              "accessionNumber" => ["0000320193-26-000004"],
              "filingDate" => ["2026-05-22"],
              "form" => ["8-K"],
              "items" => [""]
            }
          }
        },
        cik: 320193,
        forms: ["8-K"],
        since: Time.utc(2026, 5, 20)
      )

      assert_equal ["?"], items.map(&:item_code)
      assert_equal Time.utc(2026, 5, 22), items.first.filed_at
    end
  end
end
