require 'uri'
require 'net/http'
require 'json'

class GridController < ApiController
  def data
    uri = URI('https://raw.githubusercontent.com/keaysma/fiarfli.art/master/src/components/index.json')
    res = Net::HTTP.get_response(uri)
    @data = JSON.parse(res.body)
    render json: @data
  end

  def update
    puts "\n"
    
    if !params.key?(:token)
      render json: {
        error: "missing 'token' key"
      }
      return
    end
    
    if !params.key?(:blocks)
      render json: {
        error: "missing 'blocks' key"
      }
      return
    end

    if !params.key?(:media)
      render json: {
        error: "missing 'media' key"
      }
    end

    if !params.key?(:content)
      render json: {
        error: "missing 'content' key"
      }
      return
    end

    token = params[:token]
    new_blocks = params[:blocks]
    new_media = params[:media]
    new_content = params[:content]
    @content = new_content

    res = Net::HTTP.get_response(URI('https://raw.githubusercontent.com/keaysma/fiarfli.art/master/src/components/index.json'))
    @index = JSON.parse(res.body)

    @index[:blocks] = new_blocks

    #curl -L "https://..." -H "Authorization: token $token" --data ''

    #1. Get latest commit hash from the head of master
    #curl -H "Authorization: token $token" -L https://api.github.com/repos/keaysma/fiarfli.art/git/refs/heads/master
    #commit_url = res[:object][:url]
    #commit_hash = res[:object][:sha]
    uri = URI("https://api.github.com/repos/keaysma/fiarfli.art/git/refs/heads/master")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "token #{token}"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
      http.request(req)
    }
    res_data = JSON.parse(res.body)

=begin
    if res.is_a?(Net::HTTPUnauthorized)
      render json: {
        message: "Upstream Failure",
        ustream_response: res_data
      }
      return
    end
=end
    
    commit_url = res_data["object"]["url"]
    commit_hash = res_data["object"]["sha"]

    #2. Get the commit's data
    #curl -H "Authorization: token $token" -L $commit_url
    #tree_url = res[:tree][:url]
    #tree_hash = res[:tree][:sha]
    uri = URI(commit_url)
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "token #{token}"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
      http.request(req)
    }
    res_data = JSON.parse(res.body)
    tree_url = res_data["tree"]["url"]
    tree_hash = res_data["tree"]["sha"]

    #3. Get the tree
    #curl -H "Authorization: token $token" -L "$(tree_url)?recursive=1"
    #skipped - not needed
    uri = URI("#{tree_url}?recursive=1")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "token #{token}"
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
      http.request(req)
    }
    res_data = JSON.parse(res.body)
    tree_data = res_data["tree"]

    puts "Get existing tree"
    p tree_data
    puts "\n"

    # locate filenames in the existing tree that are not used, add them to the tree as empty to remove them
    new_art_nodes = new_blocks.map { |item| item["content"] }
    new_art_nodes = new_art_nodes.flatten
    new_art_nodes = new_art_nodes.map { |item| "public" + item["path"].sub(/\.[^.]*$/, '') }
    
    existing_art_nodes = tree_data.select { |item| item["path"].match(/public\/art/) && item["type"] != "tree" }
    existing_art_nodes = existing_art_nodes.map { |item| item["path"] }

    remove_art_nodes = existing_art_nodes.select { |item| ! new_art_nodes.include? item.sub(/\.[^.]*$/, '') }

    puts "removing"
    p remove_art_nodes

    remove_content_tree = remove_art_nodes.map { |item| 
      ({
        "path": item,
        "mode": "100644",
        "type": "blob",
        "sha": nil
      })
    }

    #4. Send the new file
    #curl -H "Authorization: token $token" -X POST -L https://api.github.com/repos/keaysma/fiarfli.art/git/blobs --data '{"content": "{}"}'
    #obj_url = res[:url]
    #obj_hash = res[:sha]
    content_name_conversion = {}
    content_tree = new_media.map! {|item| 
      item_name = item["name"]
      item_content = item["content"]

      if item_name.match(/\.(png|jpg|jpeg)$/) then
        webp_name = item["name"].sub(/\.[^.]*$/, '.webp')
        p "#{item_name} -> #{webp_name}"

        content_name_conversion[item_name] = webp_name
        item_name = webp_name
        item_content = helpers.convert_to_webp(item["content"])
      end

      uri = URI("https://api.github.com/repos/keaysma/fiarfli.art/git/blobs")
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "token #{token}"
      req["Content-Type"] = "application/json"

      req.body = {"content": item_content, "encoding": "base64"}.to_json
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
        http.request(req)
      }
      res_data = JSON.parse(res.body)
      
      ({
        "path": "public" + item_name,
        "mode": "100644",
        "type": "blob",
        "sha": res_data["sha"]
      })
    }

    puts "media uploaded"
    p content_tree
    puts "\n"

    @index[:"blocks"] = @index[:"blocks"].map! {|block|
      block[:"content"] = block[:"content"].map! {|block_content|
        new_name = content_name_conversion[block_content[:"path"]]
        if !new_name.nil? then
          block_content[:"path"] = new_name
        end
        
        block_content
      }

      block
    }
    uri = URI("https://api.github.com/repos/keaysma/fiarfli.art/git/blobs")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "token #{token}"
    req["Content-Type"] = "application/json"
    req.body = {"content": @index.to_json.to_s}.to_json
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
      http.request(req)
    }
    res_data = JSON.parse(res.body)
    obj_url = res_data["url"]
    obj_hash = res_data["sha"]

    puts "index.json uploaded"
    p res_data
    p obj_hash
    puts "\n"

    uri = URI("https://api.github.com/repos/keaysma/fiarfli.art/git/blobs")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "token #{token}"
    req["Content-Type"] = "application/json"
    req.body = {"content": @content.to_json.to_s}.to_json
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
      http.request(req)
    }
    res_data = JSON.parse(res.body)
    content_url = res_data["url"]
    content_hash = res_data["sha"]

    puts "content.json uploaded"
    p res_data
    p content_hash
    puts "\n"

    #Example data:
    #{
    #  "sha": "f78b831869101f29a05b0cc5c8ec395744090692",
    #  "url": "https://api.github.com/repos/keaysma/fiarfli.art/git/blobs/f78b831869101f29a05b0cc5c8ec395744090692"
    #}

    # Send new content


    #5. modify the recursive tree, replacing the "sha" and "url" values for the file with "path": "src/components/state.js"
    #just kidding we can skip this

    #6. Upload the new tree
    #curl -H "Authorization: token $token" -X POST -L https://api.github.com/repos/keaysma/fiarfli.art/git/trees --data '{"tree": tree}'
    #new_tree_url = res[:tree][:url]
    #new_tree_hash = res[:tree][:sha]
    uri = URI("https://api.github.com/repos/keaysma/fiarfli.art/git/trees")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "token #{token}"
    req["Content-Type"] = "application/json"
    req.body = {
      "base_tree": tree_hash,
      "tree": [
        {
          "path": "src/components/index.json",
          "mode": "100644",
          "type": "blob",
          "sha": obj_hash
        },
        {
          "path": "src/components/content.json",
          "mode": "100644",
          "type": "blob",
          "sha": content_hash
        }
      ] + content_tree + remove_content_tree
    }.to_json
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
      http.request(req)
    }
    res_data = JSON.parse(res.body)
    new_tree_url = res_data["url"]
    new_tree_hash = res_data["sha"]

    puts "tree uploaded"
    p res_data
    p new_tree_hash
    puts "\n"

    #7. Create the commit
    #curl -H "Authorization: token $token" -X POST -L https://api.github.com/repos/keaysma/fiarfli.art/git/commits --data '{"message": "automated upload", "parents": [commit_hash], "tree": new_tree_hash}'
    #new_commit_url = res[:tree][:url]
    #new_commit_hash = res[:tree][:sha]
    uri = URI("https://api.github.com/repos/keaysma/fiarfli.art/git/commits")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "token #{token}"
    req["Content-Type"] = "application/json"
    req.body = {"message": "automated upload", "parents": [commit_hash], "tree": new_tree_hash}.to_json
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
      http.request(req)
    }
    res_data = JSON.parse(res.body)
    new_commit_url = res_data["url"]
    new_commit_hash = res_data["sha"]

    puts "commit created"
    p new_commit_hash
    puts "\n"

    #8. Update head
    #curl -H "Authorization: token $token" -X PATCH -L https://api.github.com/repos/keaysma/fiarfli.art/git/refs/heads/master --data '{"sha": new_commit_hash}'
    uri = URI("https://api.github.com/repos/keaysma/fiarfli.art/git/refs/heads/master")
    req = Net::HTTP::Post.new(uri)
    req["Authorization"] = "token #{token}"
    req["Content-Type"] = "application/json"
    req.body = {"sha": new_commit_hash}.to_json
    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http|
      http.request(req)
    }

    puts "head moved"


    render json: {
      message: "success",
      data: @data
    }
  end
end
