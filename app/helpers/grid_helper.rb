require 'uri'
require 'net/http'

require 'webp_ffi'
require 'base64'
require 'tempfile'

module GridHelper
    def http(method, path, headers, body)
        uri = URI(path)
        req = Net::HTTP.method(method).new(uri)
        
        # Hard coding headers for now
        req["Authorization"] = headers["Authorization"]
        res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| 
            http.request(req)
        }

        res
    end

    def convert_to_webp(input_base64str)
        input_file = Tempfile.new(binmode: true)
        output_file = Tempfile.new(binmode: true)

        input_content = Base64.decode64(input_base64str)
        input_file.write(input_content)
        input_file.flush()
        #input_file.close()

        p input_base64str.length
        p input_content.length
        p input_file.path
        
        WebP.encode(input_file.path, output_file.path)

        output_file.rewind()
        output_content = output_file.read()
        output_base64str = Base64.encode64(output_content)

        output_base64str
    end
end
