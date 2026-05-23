module Rubyfin
  class Error < StandardError; end
  class AdapterError < Error; end
  class NotFound < Error; end
end

require_relative "rubyfin/version"
require_relative "rubyfin/records"
