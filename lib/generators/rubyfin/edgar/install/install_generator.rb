require "rails/generators"
require "rails/generators/active_record"

module Rubyfin
  module Generators
    module Edgar
      class InstallGenerator < ::Rails::Generators::Base
        include ::Rails::Generators::Migration

        source_root File.expand_path("templates", __dir__)

        def copy_migration
          migration_template "create_rubyfin_edgar_tables.rb.tt", "db/migrate/create_rubyfin_edgar_tables.rb"
        end

        def self.next_migration_number(_dirname)
          Time.now.utc.strftime("%Y%m%d%H%M%S")
        end
      end
    end
  end
end
