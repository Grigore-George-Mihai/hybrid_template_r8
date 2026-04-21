# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    # ActiveRecord errors
    rescue_from ActiveRecord::RecordNotFound do |_exception|
      error!({ errors: { status: I18n.t("errors.not_found") } }, 404)
    end

    rescue_from ActiveRecord::RecordInvalid do |exception|
      error!(
        {
          errors: {
            status: I18n.t("errors.unprocessable_entity"),
            code: 422,
            details: exception.record.errors.as_json(full_messages: true)
          }
        },
        422
      )
    end

    # Grape Validation errors
    rescue_from Grape::Exceptions::ValidationErrors do |exception|
      error!({ errors: { status: I18n.t("errors.bad_request"), code: 400, message: exception.message } }, 400)
    end

    # JWT-specific errors from devise-jwt or plain JWT.
    # JWT::VerificationError < JWT::DecodeError, so the decode handler covers it.
    rescue_from JWT::ExpiredSignature do |_e|
      error!({ errors: { status: "Unauthorized", message: "Token has expired" } }, 401)
    end

    rescue_from JWT::DecodeError do |_e|
      error!({ errors: { status: "Unauthorized", message: "Invalid token" } }, 401)
    end

    rescue_from Warden::JWTAuth::Errors::NilUser,
                Warden::JWTAuth::Errors::RevokedToken,
                Warden::JWTAuth::Errors::WrongScope do |_e|
      error!({ errors: { status: "Unauthorized", message: "Invalid token" } }, 401)
    end

    # Let Grape's own exceptions bubble up so routing/method-not-allowed/etc. keep
    # their intended status codes instead of becoming opaque 500s.
    rescue_from Grape::Exceptions::Base do |e|
      error!({ errors: { status: e.message } }, e.status || 500)
    end

    # Catch-all for unexpected errors — message is logged, never returned to the client
    rescue_from StandardError do |e|
      Rails.error.report(e, handled: true, source: "api")
      error!({ errors: { status: "Internal Server Error" } }, 500)
    end
  end
end
