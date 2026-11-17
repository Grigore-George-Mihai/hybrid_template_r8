# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Content Security Policy", type: :request do
  def script_nonce
    response.headers["content-security-policy"][/script-src[^;]*'nonce-([^']+)'/, 1]
  end

  def importmap_tag
    response.body[/<script type="importmap"[^>]*>/]
  end

  it "sends a non-empty script nonce on a visitor's first request, matching the importmap tag" do
    get new_user_session_path

    expect(script_nonce).to be_present
    expect(importmap_tag).to include(%(nonce="#{script_nonce}"))
  end

  # Signs in through the real form (not Devise's test helper) so Warden's session renewal on sign-in is exercised.
  it "keeps the nonce stable across requests and sign-in" do
    user = create(:user)
    get new_user_session_path
    first_nonce = script_nonce

    post user_session_path, params: { user: { email: user.email, password: user.password } }
    follow_redirect!

    expect(script_nonce).to eq(first_nonce)
  end

  # The JSON API is stateless: no response should carry a session cookie (ApiRoot::SkipSession).
  {
    "an /api/v1 endpoint" => [:unauthorized, -> { post "/api/v1/auth/login", params: { email: "x@example.com", password: "x" } }],
    "the Swagger doc outside /api" => [:ok, -> { get "/swagger_doc" }],
    "a body Grape's formatter rejects before endpoint code" =>
      [:bad_request, -> { post "/api/v1/auth/login", params: "{bad", headers: { "CONTENT_TYPE" => "application/json" } }]
  }.each do |description, (status, request)|
    it "sets no session cookie for #{description}" do
      instance_exec(&request)

      expect(response).to have_http_status(status)
      expect(response.headers["set-cookie"]).to be_blank
    end
  end
end
