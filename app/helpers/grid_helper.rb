require 'uri'
require 'net/http'

require 'webp_ffi'
require 'base64'
require 'tempfile'

module GridHelper
    def fetch_index_content
        NetReq.get('https://raw.githubusercontent.com/keaysma/fiarfli.art/master/src/components/index.json', nil)
    end

    def fetch_commit_info(url, token)
        res = NetReq.get(url, token)
        commit_url = res["object"]["url"]
        commit_hash = res["object"]["sha"]
        [commit_url, commit_hash]
    end

    def fetch_tree_info(url, token)
        res = NetReq.get("#{url}?recursive=1", token)
        tree_data = res_data["tree"]
        tree_data
    end

    def convert_to_webp(input_base64str)
        input_file = Tempfile.new(binmode: true)
        output_file = Tempfile.new(binmode: true)
        thumbnail_file = Tempfile.new(binmode: true)

        input_content = Base64.decode64(input_base64str)
        input_file.write(input_content)
        input_file.flush()
        input_file.close()

        WebpUtils.convert(input_file, output_file, thumbnail_file)

        output_content = output_file.read()
        output_base64str = Base64.encode64(output_content)
        output_file.close()

        output_thumbnail = thumbnail_file.read()
        output_thumbnail_base64str = Base64.encode64(output_thumbnail)
        thumbnail_file.close()

        ({
            "content": output_base64str,
            "thumbnail": output_thumbnail_base64str    
        })
    end
end
