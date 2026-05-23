module Rubyfin::Edgar
  class RateLimiter
    def initialize(pause_seconds: 0.15, sleeper: Kernel)
      @pause_seconds = pause_seconds.to_f
      @sleeper = sleeper
    end

    def pause_between_requests(current_index:, total:)
      return if @pause_seconds <= 0
      return if current_index >= total - 1

      @sleeper.sleep(@pause_seconds)
    end
  end
end
