im = require  'imagemagick'
serialize = require '../assets/js/serialize_pixel'

create_gif = (chars, dest, fn) ->
  frames = serialize.decode_pxl(chars)
  convert_args = "-delay 20 -dispose previous -loop 0 -fill black -size #{serialize.PXL.width}x#{serialize.PXL.height}".split(" ")
  for frame in frames
    convert_args = convert_args.concat([
      "(", "xc:white", "-draw"
    ])
    draw_args = []
    for row,y in frame
      for bit,x in row
        if bit
          draw_args.push("point #{x},#{y}")
    convert_args.push(draw_args.join(" "))
    convert_args.push(")")
  convert_args = convert_args.concat(["-scale", "32x32", dest])
  im.convert(convert_args, fn)

module.exports = { create_gif }
