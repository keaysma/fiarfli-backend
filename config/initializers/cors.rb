Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
        origins 'http://gignote.test'
        resource '*', headers: :any, methods: [:get, :post, :put]
    end
end