module Rubyfin::Rails::Fred
  class Observation < ApplicationRecord
    self.table_name = "rubyfin_fred_observations"

    belongs_to :series,
      class_name: "Rubyfin::Rails::Fred::Series",
      foreign_key: :rubyfin_fred_series_id,
      inverse_of: :observations

    validates :series_id, :observed_on, presence: true
  end
end
