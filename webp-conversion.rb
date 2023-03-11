require 'webp_ffi'


[
    "/skitty.jpg"
].map {|x| 
    input_path = File.expand_path("../fiarfli.art/public"+x)
    output_webp_path = File.expand_path("../fiarfli.art/public"+x).sub(/\.(png|jpg|jpeg)/, '.webp')
    puts(input_path); 
    puts(output_webp_path); 
    WebP.encode(
        input_path,
        output_webp_path, 
        quality: 75, 
    )
}