# frozen_string_literal: true

class ApiRoot < Grape::API
  include ErrorHandler

  # The API is stateless (JWT): never persist the Rails session, so no session cookie is sent
  # even when middleware (e.g. the CSP nonce generator) touches it.
  before { env[Rack::RACK_SESSION_OPTIONS][:skip] = true }

  mount V1::Api

  add_swagger_documentation(
    api_version: "v1",
    base_path: "/",
    hide_documentation_path: true,
    mount_path: "/swagger_doc",
    hide_format: true,
    security_definitions: {
      bearerAuth: {
        type: "apiKey",
        name: "Authorization",
        in: "header",
        description: "Enter JWT token as `Bearer {token}`"
      }
    },
    security: [{ bearerAuth: [] }],
    models: [
      V1::Entities::AuthEntity
    ]
  )
end
