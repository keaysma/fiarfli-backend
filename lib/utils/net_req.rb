require 'uri'
require 'net/http'

module NetReq
    extend self
    
    def get(path, token)
        uri = URI(path)
        req = Net::HTTP::Get.new(uri)
        
        if token then
            req["Authorization"] = "token #{token}"
        end
        
        
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| 
            http.request(req)
        }

        res_data = JSON.parse(res.body)
        res_data
    end

    def post(path, token, body)
        uri = URI(path)
        req = Net::HTTP::Post.new(uri)
        
        if token then
            req["Authorization"] = "token #{token}"
        end

        req.body = body
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| 
            # http.request(req)
            p req.body
        }

        res_data = JSON.parse(res.body)
        res_data
    end
end