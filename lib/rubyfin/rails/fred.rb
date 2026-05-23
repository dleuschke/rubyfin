require "rubyfin/fred"

begin
  require "active_record"
rescue LoadError
  raise LoadError, "rubyfin/rails/fred requires Active Record. Add Rails or the activerecord gem before requiring rubyfin/rails/fred."
end

module Rubyfin
  module Rails
    module Fred
    end
  end
end

require_relative "fred/models"
require_relative "fred/ingestor"
require_relative "fred/engine" if defined?(::Rails::Engine)
