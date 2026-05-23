require "rubyfin/edgar"

begin
  require "active_record"
rescue LoadError
  raise LoadError, "rubyfin/rails/edgar requires Active Record. Add Rails or the activerecord gem before requiring rubyfin/rails/edgar."
end

module Rubyfin
  module Rails
    module Edgar
    end
  end
end

require_relative "edgar/models"
require_relative "edgar/ingestor"
require_relative "edgar/engine" if defined?(::Rails::Engine)
