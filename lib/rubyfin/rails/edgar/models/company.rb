module Rubyfin::Rails::Edgar
    class Company < ApplicationRecord
      self.table_name = "rubyfin_edgar_companies"

      has_many :filings,
        class_name: "Rubyfin::Rails::Edgar::Filing",
        foreign_key: :rubyfin_edgar_company_id,
        inverse_of: :company,
        dependent: :destroy
      has_many :company_facts,
        class_name: "Rubyfin::Rails::Edgar::CompanyFact",
        foreign_key: :rubyfin_edgar_company_id,
        inverse_of: :company,
        dependent: :destroy

      validates :cik, presence: true, uniqueness: true
      validates :ticker, presence: true
    end
end
