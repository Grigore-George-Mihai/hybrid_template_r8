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

  it "keeps the nonce stable across requests and sign-in" do
    get new_user_session_path
    first_nonce = script_nonce

    sign_in create(:user)
    get root_path

    expect(script_nonce).to eq(first_nonce)
  end

  it "does not set a session cookie on API responses" do
    post "/api/v1/auth/login", params: { email: "nobody@example.com", password: "wrong" }

    expect(response.headers["set-cookie"]).to be_blank
  end
end
