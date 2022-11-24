[
    "/art/a mural thing shirt design.png",
    "/art/Thibault commission smol.png",
    "/art/fallwitchin sticker.png",
    "/art/honke sticker.png",
    "/art/Inside front cover.png",
    "/art/vegalia dtiys mo.png",
    "/art/Liza's mural higher res.png",
    "/art/Starryclouds.png",
    "/art/bg1.png",
    "/art/Physics Mural.jpeg",
    "/art/Hangin original.png",
    "/art/Drawing FINAL straightened.png",
    "/art/blue_peony.png",
    "/art/golden poison froggo.png",
    "/art/Illustration4.png",
    "/art/Illustration flip.png",
    "/art/Gaius and Skitty.png",
    "/art/Hangin.png",
    "/art/starry cloud backdrop.png"
].map {|x| 
    input_path = File.expand_path("../fiarfli.art/public"+x)
    input_webp_path = input_path.sub(/\.(png|jpg|jpeg)/, '.webp')
    output_webp_path = File.expand_path("../fiarfli.art/public/thumbnail"+x).sub(/\.(png|jpg|jpeg)/, '.webp')
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