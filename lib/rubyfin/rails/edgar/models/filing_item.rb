module Rubyfin::Rails::Edgar
    class FilingItem < ApplicationRecord
      self.table_name = "rubyfin_edgar_filing_items"

      belongs_to :filing,
        class_name: "Rubyfin::Rails::Edgar::Filing",
        foreign_key: :rubyfin_edgar_filing_id,
        inverse_of: :filing_items

      validates :cik, :accession, :code, presence: true
    end
end
