Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
        origins 'http://gignote.test', 'https://fiarfli.keays.io', 'https://fiarfli.art'
        resource '*', headers: :any, methods: [:get, :post, :put]
    end
end