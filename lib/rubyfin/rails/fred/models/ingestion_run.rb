module Rubyfin::Rails::Fred
  class IngestionRun < ApplicationRecord
    self.table_name = "rubyfin_fred_ingestion_runs"

    validates :status, :scope, presence: true
  end
end
