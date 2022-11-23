require 'uri'
require 'net/http'

require 'webp_ffi'
require 'base64'
require 'tempfile'

module GridHelper
    def get(path, token)
        uri = URI(path)
        req = Net::HTTP::Get.new(uri) #Net::HTTP.method(method).new(uri)
        
        # Hard coding headers for now
        req["Authorization"] = "token #{token}" #headers["Authorization"]
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| 
            http.request(req)
        }

        res_data = JSON.parse(res.body)
        res_data
    end

    def post(path, token, body)
        uri = URI(path)
        req = Net::HTTP::Post.new(uri)
        
        # Hard coding headers for now
        req["Authorization"] = "token #{token}" #headers["Authorization"]
        req.body = body
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| 
            http.request(req)
        }

        res_data = JSON.parse(res.body)
        res_data
    end

    def convert_to_webp(input_base64str)
        input_file = Tempfile.new(binmode: true)
        output_file = Tempfile.new(binmode: true)
        thumbnail_file = Tempfile.new(binmode: true)

        input_content = Base64.decode64(input_base64str)
        input_file.write(input_content)
        input_file.flush()
        input_file.close()
        #input_file.close()

        p input_base64str.length
        p input_content.length
        p input_file.path
        
        WebP.encode(input_file.path, output_file.path)

        output_file.rewind()
        output_content = output_file.read()
        output_base64str = Base64.encode64(output_content)
        output_file.close()

        webp_size = WebP.webp_size(output_content)
        WebP.encode(input_file.path, thumbnail_file.path, quality: 95, resize_w: (webp_size[0] * 0.5).to_int, resize_h: (webp_size[1] * 0.5).to_int)
        output_thumbnail = thumbnail_file.read()
        output_thumbnail_base64str = Base64.encode64(output_thumbnail)
        thumbnail_file.close()

        ({
            "content": output_base64str,
            "thumbnail": output_thumbnail_base64str    
        })
    end
end
