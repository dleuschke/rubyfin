module Rubyfin::Rails::Fred
  class ApplicationRecord < ::ActiveRecord::Base
    self.abstract_class = true
  end
end
