module Rubyfin::Rails::Edgar
    class CompanyFact < ApplicationRecord
      self.table_name = "rubyfin_edgar_company_facts"

      belongs_to :company,
        class_name: "Rubyfin::Rails::Edgar::Company",
        foreign_key: :rubyfin_edgar_company_id,
        inverse_of: :company_facts

      validates :cik, :taxonomy, :tag, presence: true
    end
end
