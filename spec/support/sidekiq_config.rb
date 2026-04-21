# frozen_string_literal: true

require "rspec-sidekiq"

# rspec-sidekiq enables Sidekiq::Testing.fake! automatically; this silences its
# informational "Sidekiq will NOT process jobs in this environment" banner.
RSpec::Sidekiq.configure do |config|
  config.warn_when_jobs_not_processed_by_sidekiq = false
end

RSpec.configure do |config|
  # Clear all job queues before each example
  config.before do
    Sidekiq::Job.clear_all
  end
end
