require 'uri'
require 'net/http'
require 'json'

class GridController < ApiController

  def data
    token = request.headers["X-Git-Token"]
    render json: JSON.pretty_generate({
      "head": helpers.fetch_head_info("master", token),
      "index": helpers.fetch_index_file("master", token).as_json,
      "content": helpers.fetch_content_file("master", token).as_json
    })
  end

  def head
    token = request.headers["X-Git-Token"]
    render json: JSON.pretty_generate({
      "head": helpers.fetch_head_info("master", token)
    })
  end

  def update
    token = request.headers["X-Git-Token"]

    if !token then
      render json: {
        error: "missing token"
      }
      return
    end

    if (!params.key?(:blocks) or params[:blocks].empty?) or
       (!params.key?(:content) or params[:content].empty?) or
       (!params.key?(:media))
    then
      render json: {
        error: "missing parameters, requires 'token', 'blocks', 'media', and 'content'"
      }
      return
    end
    
    new_blocks, new_media, new_content = params.values_at(:blocks, :media, :content)
    
    #0. Get the current index.json, and update it with the new blocks
    @index = helpers.fetch_index_file("master", token)
    @index["blocks"] = new_blocks

    #1. Get latest commit hash from the head of master
    commit_hash = helpers.fetch_head_info("master", token)

    #2. Get the commit's data
    tree_hash = helpers.fetch_tree_info(commit_hash, token)
    puts "Existing tree hash: #{tree_hash}\n"

    #3. Get the tree
    tree_data = helpers.fetch_tree(tree_hash, token)

    # puts "Existing tree:\n#{tree_data}\n"

    # locate filenames in the existing tree that are not used, add them to the tree as empty to remove them
    new_art_nodes_index = new_blocks.map{ |item| item["content"] }.flatten
    new_art_node_paths = new_art_nodes_index.map { |item| item["path"].sub(/\.[^.]*$/, '')  }

    new_art_nodes = new_art_node_paths.map { |path| "public" + path}
    # assume thumbnail will stay if it exists
    new_art_nodes += new_art_node_paths.map { |path| "public/thumbnail" + path }

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
      name, content = item.values_at(:name, :content)

      if name.match(/\.(png|jpg|jpeg)$/) then
        webp_name = name.sub(/\.[^.]*$/, '.webp')
        webp_data = helpers.convert_to_webp(content)
        
        p "#{name} -> #{webp_name}"
        
        content_name_conversion[name] = webp_name
        thumbnails[name] = webp_data[:thumbnail]

        name = webp_name
        content = webp_data[:content]
      end

      
      sha = helpers.upload_blob(content, token)
      
      ({
        "path": "public" + name,
        "mode": "100644",
        "type": "blob",
        "sha": sha
      })
    }

    puts "media uploaded\n#{content_tree}\n"

    @index["blocks"] = @index["blocks"].map! {|block|
      block["content"] = block["content"].map! {|block_content|
        old_name = block_content["path"]
        new_name = content_name_conversion[old_name]
        if !new_name.nil? then
          block_content["path"] = new_name

          thumbnail_content = thumbnails[old_name]
          if !thumbnail_content.nil? then
            block_content["thumbnail"] = "thumbnail" + new_name

            sha = helpers.upload_blob(thumbnail_content, token)
            content_tree += [{
              "path": "public/thumbnail" + new_name,
              "mode": "100644",
              "type": "blob",
              "sha": sha
            }]
          end
        end
        
        block_content
      }

      block
    }

    puts "thumbnails uploaded\n#{content_tree}\n"

    index_sha = helpers.upload_blob(JSON.pretty_generate(@index.as_json), token)
    puts "index.json uploaded: #{index_sha}\n"

    content_sha = helpers.upload_blob(JSON.pretty_generate(new_content.as_json), token)
    puts "content.json uploaded: #{content_sha}\n"

    #5. modify the recursive tree, replacing the "sha" and "url" values for the file with "path": "src/components/state.js"
    #just kidding we can skip this

    #6. Upload the new tree
    new_tree_hash = helpers.upload_tree(
      tree_hash,
      [
        {
          "path": "src/components/index.json",
          "mode": "100644",
          "type": "blob",
          "sha": index_sha
        },
        {
          "path": "src/components/content.json",
          "mode": "100644",
          "type": "blob",
          "sha": content_sha
        }
      ] + content_tree + remove_content_tree, 
      token
    )

    puts "tree uploaded: #{new_tree_hash}\n"

    #7. Create the commit
    new_commit_hash = helpers.upload_commit("🌞 automated upload 🌞", [commit_hash], new_tree_hash, token)
    puts "commit created: #{new_commit_hash}\n"

    #8. Update head
    helpers.update_head("master", new_commit_hash, token)
    puts "head moved to #{new_commit_hash}\n"


    render json: {
      message: "success",
      data: @data
    }
  end
end
