PXL = {
  width: 16
  height: 16
  encode: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
  separator: "~"
  max_num_frames: 16
  output_scale: 2
}
PXL.decode = {}
for char,i in PXL.encode
  PXL.decode[char] = i
PXL.frame_length = Math.ceil(PXL.width * PXL.height / 6)

normalize_pxl = (chars) ->
  frames = chars.split(PXL.separator).slice(0, PXL.max_num_frames)
  for chars,i in frames
    frames[i] = chars + ("A" for a in [0...PXL.frame_length - chars.length]).join("")
    frames[i] = frames[i].substring(0, PXL.frame_length)
  return frames.join("~")

decode_pxl = (chars) ->
  chars = normalize_pxl(chars)
  frames = []
  for frame_chars in chars.split("~")
    frame = []
    pos = -1
    count = 0
    for char in frame_chars
      integer = PXL.decode[char]
      binstr = integer.toString(2)
      bits = (0 for i in [0...(6 - binstr.length)]).concat(parseInt(b) for b in binstr)
      for bit in bits
        if count == PXL.width * PXL.height
          break
        if count % PXL.width == 0
          frame.push([])
          pos += 1
        frame[pos].push(bit)
        count += 1
    frames.push(frame)
  return frames

encode_pxl = (frames) ->
  # Turn an array of frames into a character sequence.
  frame_chars = []
  frame_count = 0
  for frame in frames
    frame_count += 1
    chars = []
    cur = []
    count = 0
    total = PXL.height * PXL.width
    for r in [0...PXL.height]
      for c in [0...PXL.width]
        count += 1
        cur.push(frame[r][c])
        # Push the char every 6 bits and at the end.
        if cur.length == 6 or (count == total)
          while cur.length != 6
            cur.push(0)
          chars.push(PXL.encode[parseInt(cur.join(""), 2)])
          cur = []
    frame_chars.push(chars.join(""))
    if frame_count == PXL.max_num_frames
      break
  return frame_chars.join(PXL.separator)

exports = { PXL, encode_pxl, decode_pxl, normalize_pxl }
if module?
  module.exports = exports
else if typeof(window) != "undefined"
  for k,v of exports
    window[k] = v
