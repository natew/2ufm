require 'delayed/worker'

# Config
Delayed::Worker.destroy_failed_jobs = true
Delayed::Worker.max_attempts = 1
Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.logger = Rails.logger

module Delayed
  class Worker
    def say_with_flushing(text, level = Logger::INFO)
      if logger
        say_without_flushing(text, level)
        Rails.logger.flush
      end
    end
    alias_method_chain :say, :flushing
  end
end