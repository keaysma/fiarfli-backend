require 'webp_ffi'


[
    "/skitty.jpg"
].map {|x| 
    input_path = File.expand_path("../fiarfli.art/public"+x)
    input_webp_path = input_path.sub(/\.(png|jpg|jpeg)/, '.webp')
    output_webp_path = File.expand_path("../fiarfli.art/public"+x+".thumb").sub(/\.(png|jpg|jpeg)/, '.webp')
    puts(input_path); 
    puts(input_webp_path); 
    puts(output_webp_path); 
    f = File.open(input_webp_path); 
    s=WebP.webp_size(f.read);
    WebP.encode(
        input_path,
        output_webp_path, 
        quality: 95, 
        resize_w: (s[0]*0.5).to_int, 
        resize_h: (s[1]*0.5).to_int
    )
}