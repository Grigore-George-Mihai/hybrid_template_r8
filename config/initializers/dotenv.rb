# frozen_string_literal: true

Dotenv.require_keys("DEVISE_JWT_SECRET_KEY") if defined?(Dotenv) && Rails.env.local?
