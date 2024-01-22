require 'uri'
require 'net/http'
require 'json'

class GridController < ApiController

  def data
    render json: helpers.fetch_index_content()
  end

  def update
    if (!params.key?(:token) or params[:token].empty?) or
       (!params.key?(:blocks) or params[:blocks].empty?) or
       (!params.key?(:media) or params[:media].empty?) or
       (!params.key?(:content) or params[:content].empty?) 
    then
      render json: {
        error: "missing parameters, requires 'token', 'blocks', 'media', and 'content'"
      }
      return
    end
    
    token, new_blocks, new_media, new_content = params.values_at(:token, :blocks, :media, :content)
    
    #0. Get the current index.json, and update it with the new blocks
    @index = helpers.fetch_index_content()
    @index[:blocks] = new_blocks

    #1. Get latest commit hash from the head of master
    commit_url, commit_hash = helpers.fetch_commit_info("https://api.github.com/repos/keaysma/fiarfli.art/git/refs/heads/master", token)

    #2. Get the commit's data
    tree_url, tree_hash = helpers.fetch_commit_info(commit_url, token)

    #3. Get the tree
    tree_data = helpers.fetch_tree_info(tree_url, token)

    puts "Existing tree:\n#{tree_data}\n"

    # locate filenames in the existing tree that are not used, add them to the tree as empty to remove them
    new_art_nodes_index = new_blocks.map { |item| item["content"] }
    new_art_nodes_index = new_art_nodes_index.flatten
    new_art_nodes = new_art_nodes_index.map { |item| "public" + item["path"].sub(/\.[^.]*$/, '') }
    # assume thumbnail will stay if it exists
    new_art_nodes += new_art_nodes_index.map { |item| "public/thumbnail" + item["path"].sub(/\.[^.]*$/, '') }
    
    existing_art_nodes_base = tree_data.select { |item| (item["path"].match(/public\/art/) || item["path"].match(/public\/thumbnail\/art/)) && item["type"] != "tree" }
    existing_art_nodes = existing_art_nodes_base.map { |item| item["path"] }
    
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
    content_name_conversion = {}
    thumbnails = {}
    content_tree = new_media.map! {|item| 
      item_name = item["name"]
      item_content = item["content"]

      if item_name.match(/\.(png|jpg|jpeg)$/) then
        webp_name = item["name"].sub(/\.[^.]*$/, '.webp')
        webp_data = helpers.convert_to_webp(item_content)
        
        p "#{item_name} -> #{webp_name}"
        
        content_name_conversion[item_name] = webp_name
        thumbnails[item_name] = webp_data[:thumbnail]

        item_name = webp_name
        item_content = webp_data[:content]
      end

      
      res_data = helpers.post("https://api.github.com/repos/keaysma/fiarfli.art/git/blobs", token, {"content": item_content, "encoding": "base64"}.to_json)
      
      ({
        "path": "public" + item_name,
        "mode": "100644",
        "type": "blob",
        "sha": res_data["sha"]
      })
    }

    puts "media uploaded\n#{content_tree}\n"

    @index[:"blocks"] = @index[:"blocks"].map! {|block|
      block[:"content"] = block[:"content"].map! {|block_content|
        old_name = block_content[:"path"]
        new_name = content_name_conversion[old_name]
        if !new_name.nil? then
          block_content[:"path"] = new_name

          thumbnail_content = thumbnails[old_name]
          if !thumbnail_content.nil? then
            block_content[:"thumbnail"] = "thumbnail" + new_name

            res_data = helpers.post(
              "https://api.github.com/repos/keaysma/fiarfli.art/git/blobs", token, 
              {"content": thumbnail_content, "encoding": "base64"}.to_json
            )
            content_tree += [{
              "path": "public/thumbnail" + new_name,
              "mode": "100644",
              "type": "blob",
              "sha": res_data["sha"]
            }]
          end
        end
        
        block_content
      }

      block
    }

    puts "thumbnails uploaded\n#{content_tree}\n"

    res_data = helpers.post(
      "https://api.github.com/repos/keaysma/fiarfli.art/git/blobs", token,
      {"content": @index.to_json.to_s}.to_json
    )
    obj_url = res_data["url"]
    obj_hash = res_data["sha"]

    puts "index.json uploaded\n#{res_data}\n#{obj_hash}\n"

    res_data = helpers.post(
      "https://api.github.com/repos/keaysma/fiarfli.art/git/blobs", token,
      {"content": new_content.to_json.to_s}.to_json
    )
    content_url = res_data["url"]
    content_hash = res_data["sha"]

    puts "content.json uploaded\n#{res_data}\n#{content_hash}\n"

    #5. modify the recursive tree, replacing the "sha" and "url" values for the file with "path": "src/components/state.js"
    #just kidding we can skip this

    #6. Upload the new tree
    res_data = helpers.post(
      "https://api.github.com/repos/keaysma/fiarfli.art/git/trees", token,
      {
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
    )
    new_tree_url = res_data["url"]
    new_tree_hash = res_data["sha"]

    puts "tree uploaded\n#{res_data}\n#{new_tree_hash}\n"

    #7. Create the commit
    res_data = helpers.post(
      "https://api.github.com/repos/keaysma/fiarfli.art/git/commits", token,
      {"message": "automated upload", "parents": [commit_hash], "tree": new_tree_hash}.to_json
    )
    new_commit_url = res_data["url"]
    new_commit_hash = res_data["sha"]

    puts "commit created\n#{new_commit_hash}\n"

    #8. Update head
    helpers.post(
      "https://api.github.com/repos/keaysma/fiarfli.art/git/refs/heads/master", token,
      {"sha": new_commit_hash}.to_json
    )

    puts "head moved"


    render json: {
      message: "success",
      data: @data
    }
  end
end
