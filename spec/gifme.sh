convert -delay 20 -loop 0 -dispose previous -fill black -size 16x16 \
    \( xc:white -draw "point 8,8" \) \
    \( xc:white -draw "point 10,10" \) \
    \( xc:white -draw "point 12,12" \) \
    \( xc:white -draw "point 14,14" \) \
    -scale 64x64 out.gif ; eog out.gif
