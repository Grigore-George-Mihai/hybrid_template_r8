# frozen_string_literal: true

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self # add specific hosts here if you load third-party scripts
    policy.style_src   :self, :https, :unsafe_inline # Tailwind (and Swagger UI) require inline styles
    policy.connect_src :self, :https
  end

  # Per-session nonce (the importmap tag is Turbo-tracked, so a per-request nonce would force full reloads).
  # Stored in the session because `request.session.id` is blank on a first visit and rotates on sign-in.
  # The Grape API never persists the session (ApiRoot::SkipSession), so this never sets a cookie on API responses.
  config.content_security_policy_nonce_generator = ->(request) { request.session[:csp_nonce] ||= SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
