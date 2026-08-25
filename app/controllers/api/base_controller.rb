module Api
  # Shared behavior for API controllers: JSON:API error rendering and the
  # mapping from domain errors to HTTP statuses.
  class BaseController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_bad_request
    rescue_from GeolocationInput::InvalidError, with: :render_unprocessable_content
    rescue_from IpResolver::ResolutionError, with: :render_unprocessable_content
    rescue_from Geolocations::AlreadyExistsError, with: :render_conflict
    rescue_from Geolocations::ValidationFailedError, with: :render_unprocessable_content
    rescue_from GeolocationProviders::InvalidLookupError, with: :render_unprocessable_content
    rescue_from GeolocationProviders::UnavailableError, with: :render_bad_gateway

    private

    def render_not_found(exception)
      render_error(status: :not_found, title: "Not Found", detail: exception.message)
    end

    def render_bad_request(exception)
      render_error(status: :bad_request, title: "Bad Request", detail: exception.message)
    end

    def render_unprocessable_content(exception)
      render_error(status: :unprocessable_content, title: "Unprocessable Entity", detail: exception.message)
    end

    def render_conflict(exception)
      render_error(status: :conflict, title: "Conflict", detail: exception.message)
    end

    def render_bad_gateway(exception)
      render_error(status: :bad_gateway, title: "Bad Gateway", detail: exception.message)
    end

    def render_error(status:, title:, detail:)
      error = { status: Rack::Utils.status_code(status).to_s, title: title, detail: detail }
      render json: { errors: [ error ] }, status: status, content_type: "application/vnd.api+json"
    end
  end
end
