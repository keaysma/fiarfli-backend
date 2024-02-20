require 'uri'
require 'net/http'
require 'json'

class ForgerController < ApiController

  def data
    token = request.headers["X-Git-Token"]
    NetReq.get("https://api.github.com/repos/keaysma/fiarfli.art/git/refs/heads/master", token)

    url = request.params["url"]
    uri = URI(URI.decode(url))
    req = Net::HTTP::Get.new(uri)
    
    
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| 
        http.request(req)
    }

    text = res.body.force_encoding('utf-8')

    # send content-type header
    response.headers['Content-Type'] = 'text/html; charset=utf-8'

    render plain: text
  end
end