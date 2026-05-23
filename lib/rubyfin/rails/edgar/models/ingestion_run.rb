module Rubyfin::Rails::Edgar
    class IngestionRun < ApplicationRecord
      self.table_name = "rubyfin_edgar_ingestion_runs"

      validates :status, :scope, presence: true
    end
end
