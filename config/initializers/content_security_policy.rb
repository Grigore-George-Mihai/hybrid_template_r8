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

  # Nonce for importmap/inline scripts (avoids unsafe-inline on script-src).
  # Stable per session, not per request: the importmap tag is Turbo-tracked, so a nonce that changes
  # on every response would force a full reload on each navigation. Stored in the session instead of
  # using `request.session.id`, which is blank on a visitor's first request (empty nonce = scripts blocked)
  # and changes when Devise rotates the session id on sign-in.
  #
  # Skipped for the Grape API: the CSP middleware runs on every response, and writing the session there
  # would send a session cookie with every JSON response of the stateless JWT API.
  config.content_security_policy_nonce_generator = lambda do |request|
    request.session[:csp_nonce] ||= SecureRandom.base64(16) unless request.path.start_with?("/api/")
  end
  config.content_security_policy_nonce_directives = %w[script-src]
end
