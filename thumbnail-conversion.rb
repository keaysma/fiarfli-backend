require 'webp_ffi'
ART_FOLDER_RELATIVE_PATH = "../fiarfli.art/public"

input_paths = [
    "/art/peachy_biker.jpeg"
]

puts("Converting to WebP...")

input_paths.map {| path | 
    input_full_path = File.expand_path(ART_FOLDER_RELATIVE_PATH + path)
    puts(input_full_path); 
    
    input_webp_path = input_full_path.sub(/\.(png|jpg|jpeg)/, '.webp')
    puts(input_webp_path); 
    
    f = File.open(input_webp_path); 
    s = WebP.webp_size(f.read);
    
    output_webp_path = File.expand_path(ART_FOLDER_RELATIVE_PATH + "/thumbnail" + path).sub(/\.(png|jpg|jpeg)/, '.webp')
    puts(output_webp_path); 

    WebP.encode(
        input_full_path,
        output_webp_path, 
        quality: 95, 
        resize_w: (s[0]*0.5).to_int, 
        resize_h: (s[1]*0.5).to_int
    )
}

puts("Done converting to WebP.")
