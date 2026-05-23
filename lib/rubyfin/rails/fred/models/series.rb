module Rubyfin::Rails::Fred
  class Series < ApplicationRecord
    self.table_name = "rubyfin_fred_series"

    has_many :observations,
      class_name: "Rubyfin::Rails::Fred::Observation",
      foreign_key: :rubyfin_fred_series_id,
      inverse_of: :series,
      dependent: :destroy

    validates :series_id, presence: true, uniqueness: true
  end
end
