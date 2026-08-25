# Allow Swagger UI (and API) to be accessed from browser in development.
# In production, restrict origins to your frontend domain.
return unless Rails.env.development?
return unless defined?(Rack::Cors)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: %w[Authorization],
             max_age: 600
  end
end