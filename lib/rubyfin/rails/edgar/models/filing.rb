module Rubyfin::Rails::Edgar
    class Filing < ApplicationRecord
      self.table_name = "rubyfin_edgar_filings"

      belongs_to :company,
        class_name: "Rubyfin::Rails::Edgar::Company",
        foreign_key: :rubyfin_edgar_company_id,
        inverse_of: :filings
      has_many :filing_items,
        class_name: "Rubyfin::Rails::Edgar::FilingItem",
        foreign_key: :rubyfin_edgar_filing_id,
        inverse_of: :filing,
        dependent: :destroy

      validates :cik, :accession, presence: true
    end
end
