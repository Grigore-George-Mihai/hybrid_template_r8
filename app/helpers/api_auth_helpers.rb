# frozen_string_literal: true

module ApiAuthHelpers
  include Pagy::Method

  # Grape helpers run inside the endpoint instance per request; instance variables
  # are the idiomatic way to memoize here. The cop below targets view helpers.
  # rubocop:disable Rails/HelperInstanceVariable
  def current_user
    return @current_user if defined?(@current_user)

    @current_user = decode_jwt_user
  end
  # rubocop:enable Rails/HelperInstanceVariable

  def authenticate_user!
    error!("401 Unauthorized", 401) unless current_user
  end

  def paginated_response(collection, entity)
    pagy_opts = { page: params[:page], limit: params[:per_page] }.compact
    pagy, records = pagy(collection, **pagy_opts)

    {
      collection.model_name.plural.to_sym => entity.represent(records, root: false),
      pagy: {
        count: pagy.count,
        page: pagy.page,
        limit: pagy.limit,
        pages: pagy.pages,
        prev_url: pagy.page_url(:previous),
        next_url: pagy.page_url(:next)
      }
    }
  end

  private

  def decode_jwt_user
    auth_header = request.headers["Authorization"]
    return nil unless auth_header&.start_with?("Bearer ")

    token = auth_header.sub(/\ABearer\s+/, "").strip
    return nil if token.empty?

    Warden::JWTAuth::UserDecoder.new.call(token, :user, nil)
  rescue JWT::DecodeError,
         Warden::JWTAuth::Errors::NilUser,
         Warden::JWTAuth::Errors::RevokedToken,
         Warden::JWTAuth::Errors::WrongScope
    nil
  end
end
