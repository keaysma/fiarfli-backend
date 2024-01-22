require 'webp_ffi'
ART_FOLDER_RELATIVE_PATH = "../fiarfli.art/public"

input_paths = [
    "/art/peachy_biker.jpeg",
]

puts("Converting to WebP...")

input_paths.map {| path | 
    input_full_path = File.expand_path(ART_FOLDER_RELATIVE_PATH + path)
    puts(input_full_path); 
    
    output_full_path = File.expand_path(ART_FOLDER_RELATIVE_PATH + path).sub(/\.(png|jpg|jpeg)/, '.webp')
    puts(output_full_path); 

    WebP.encode(
        input_full_path,
        output_full_path, 
        quality: 75, 
    )
}

puts("Done converting to WebP.")
