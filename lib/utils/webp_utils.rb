module WebpUtils
    extend self
    def convert(input_file, output_file, thumbnail_file)
        WebP.encode(input_file.path, output_file.path)
        
        output_file.rewind()
        output_content = output_file.read()
        output_file.rewind()

        if thumbnail_file then
            webp_size = WebP.webp_size(output_content)
            WebP.encode(input_file.path, thumbnail_file.path, quality: 95, resize_w: (webp_size[0] * 0.5).to_int, resize_h: (webp_size[1] * 0.5).to_int)
            thumbnail_file.rewind()
        end
    end
end