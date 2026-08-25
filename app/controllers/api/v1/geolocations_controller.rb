module Api
  module V1
    # RESTful access to stored geolocations, keyed by IP address or URL.
    class GeolocationsController < Api::BaseController
      # GET /api/v1/geolocations/:location
      def show
        render_jsonapi(Geolocations::Locator.call(params[:location]))
      end

      # POST /api/v1/geolocations
      def create
        geolocation = Geolocations::Register.call(ip_or_url_param)
        render_jsonapi(geolocation, status: :created)
      end

      # DELETE /api/v1/geolocations/:location
      def destroy
        Geolocations::Locator.call(params[:location]).destroy!
        head :no_content
      end

      private

      def ip_or_url_param
        params.require(:data).require(:attributes).require(:ip_or_url)
      end

      def render_jsonapi(record, status: :ok)
        render json: GeolocationSerializer.new(record).serializable_hash,
               status: status,
               content_type: "application/vnd.api+json"
      end
    end
  end
end
