require 'uri'
require 'net/http'

require 'webp_ffi'
require 'base64'
require 'tempfile'

module GridHelper
    def fetch_index_file(branch, token)
        sha = fetch_head_info(branch, token)
        NetReq.get("https://raw.githubusercontent.com/keaysma/fiarfli.art/#{sha}/src/components/index.json", token)
    end

    def fetch_content_file(branch, token)
        sha = fetch_head_info(branch, token)
        NetReq.get("https://raw.githubusercontent.com/keaysma/fiarfli.art/#{sha}/src/components/content.json", token)
    end

    def update_head(branch, commit_hash, token)
        NetReq.post(
            "https://api.github.com/repos/keaysma/fiarfli.art/git/refs/heads/#{branch}", token,
            {"sha": commit_hash}.to_json
        )
    end

    def fetch_head_info(branch, token)
        res = NetReq.get("https://api.github.com/repos/keaysma/fiarfli.art/git/refs/heads/#{branch}", token)
        commit_info = res["object"]
        commit_info["sha"]
    end

    def upload_commit(message, parent_hashes, tree_hash, token)
        res = NetReq.post(
            "https://api.github.com/repos/keaysma/fiarfli.art/git/commits", token,
            {
                "message": message,
                "parents": parent_hashes,
                "tree": tree_hash
            }.to_json
        )
        res["sha"]
    end

    def fetch_tree_info(hash, token)
        res = NetReq.get("https://api.github.com/repos/keaysma/fiarfli.art/git/commits/#{hash}", token)
        commit_hash = res["tree"]["sha"]
        commit_hash
    end

    def fetch_tree(url, token)
        res = NetReq.get("https://api.github.com/repos/keaysma/fiarfli.art/git/trees/#{url}?recursive=1", token)
        tree_data = res["tree"]
        tree_data
    end

    def upload_tree(base_tree, tree_data, token)
        p tree_data
        res = NetReq.post(
            "https://api.github.com/repos/keaysma/fiarfli.art/git/trees", token, 
            {
                "base_tree": base_tree, 
                "tree": tree_data
            }.to_json
        )
        p res
        res["sha"]
    end

    def upload_blob(content, token)
        body = {
            "content": Base64.encode64(content),
            "encoding": "base64"
        }.to_json
        res = NetReq.post("https://api.github.com/repos/keaysma/fiarfli.art/git/blobs", token, body)
        res["sha"]
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
        output_file.close()

        output_thumbnail = thumbnail_file.read()
        thumbnail_file.close()

        ({
            "content": output_content,
            "thumbnail": output_thumbnail    
        })
    end
end
