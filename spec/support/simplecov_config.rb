# frozen_string_literal: true

require "simplecov"

SimpleCov.start "rails" do
  skip "/lib/generators/"
end
