module HackneyAPI
  class RepairsClient
    include HttpStatusCodes

    class HackneyApiError < StandardError; end
    class RecordNotFoundError < HackneyApiError; end
    class ApiError < HackneyApiError; end

    API_CACHE_TIME_IN_SECONDS = 5.minutes.to_i
    API_VERSION = "v1"

    LEVEL_ESTATE = 2
    LEVEL_FACILITIES = 6
    LEVEL_NON_DWELL = 8

    def initialize(opts = {})
      @base_url = opts.fetch(:base_url, ENV.fetch('HACKNEY_REPAIRS_API_BASE_URL'))
    end

    def get_work_orders
      request(
        http_method: :get,
        endpoint: "#{API_VERSION}/work_orders"
      )
    end

    def get_work_order(reference)
      request(
        http_method: :get,
        endpoint: "#{API_VERSION}/work_orders/#{reference}"
      )
    end

    def get_work_orders_by_references(references)
      request(
        http_method: :get,
        endpoint: "#{API_VERSION}/work_orders/by_references",
        params: { reference: references }
      )
    end

    def work_order_feed(previous_reference)
      request(
        http_method: :get,
        endpoint: "#{API_VERSION}/work_orders/feed?startId=#{previous_reference}"
      )
    end

    def get_work_order_appointments(reference)
      request(
        http_method: :get,
        endpoint: "#{API_VERSION}/work_orders/#{reference}/appointments"
      )
    end

    def get_work_order_appointments_latest(reference)
      response = request(
        http_method: :get,
        endpoint: "#{API_VERSION}/work_orders/#{reference}/appointments/latest"
      )
      if response == []
        raise HackneyAPI::RepairsClient::RecordNotFoundError,
              "Can't find appointment for #{reference}"
      else
        response
      end
    end

    def get_property(reference)
      request(
        http_method: :get,
        endpoint: "#{API_VERSION}/properties/#{reference}"
      )
    end

    private

    def notes_endpoint(reference)
      "#{API_VERSION}/work_orders/#{reference}/notes"
    end

    def request(http_method:, endpoint:, cache_request: true, headers: {}, params: {})
      # caller = caller_locations.first.label

      response = begin
        # Appsignal.instrument("api.#{caller}") do
          connection(cache_request: cache_request, headers: headers).public_send(http_method, endpoint, params)
        # end
      rescue => e
        Rails.logger.error(e)
        raise
      end

      case response.status
      when HTTP_STATUS_OK, HTTP_STATUS_NO_CONTENT
        response.body
      when HTTP_STATUS_NOT_FOUND
        raise RecordNotFoundError, [endpoint, params].join(', ')
      else
        Rails.logger.error(e)
        #raise ApiError, [endpoint, params, response.status, response.body].join(', ')
      end
    end

    def connection(cache_request:, headers:)
       result = Faraday.new(@base_url, request: { :params_encoder => Faraday::FlatParamsEncoder }, headers: {"x-api-key"=>"#{ENV['X_API_KEY']}"}.merge(headers)) do |faraday|
        if cache_request
          faraday.use :manual_cache,
                      logger: Rails.logger,
                      expires_in: API_CACHE_TIME_IN_SECONDS,
                      cache_key: ->(env) { "hackney-api-cache-" + env.url.to_s.sub(@base_url, '') }
        end
        faraday.proxy = ENV['QUOTAGUARDSTATIC_URL']
        faraday.response :json
        faraday.response :logger, Rails.logger unless Rails.env.test?
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
