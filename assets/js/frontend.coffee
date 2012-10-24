#= require vendor/jquery
#= require vendor/underscore
#= require vendor/underscore-autoescape
#= require vendor/backbone
#= require vendor/jquery-ui-1.9.0.custom
#= require vendor/jqModal
#= require flash
#= require serialize_pixel

get_query_param = (key) ->
  for arg in window.location.search.substring(1).split('&')
    parts = arg.split('=')
    if decodeURIComponent(parts[0]) == key
      return decodeURIComponent(parts[1])
  return undefined

gallery_template = "
  <div class='gallery'>
    <h2>Fnl Ct Pr <small><small style='font-weight: normal;'>video editor</small></small></h2>
    <a href='#' class='cta cta-blue new'>New</a>
    <% for (var i = 0; i < gifs.length; i++) { %>
      <a class='gif' href='' data-index='<%= i %>'><img src='<%= gifs[i].gif %>' /></a>
    <% } %>
  </div>
  <div style='border-top: 1px solid #eee; margin-top: 1em; padding: 1em;'>
      <a href='http://github.com/yourcelf/fnlctpr'>github</a>
  </div>
"
gif_modal_template = "
  <div class='jqmWindow'>
    <div style='text-align: center;'>
      <img src='<%= gif.gif %>' /><br />
      <input size='40' readonly value='<%= window.location.protocol + '://' + window.location.host + gif.gif %>' />
      <p>
        <a class='cta cta-red edit' href='#' data-index='<%= index %>'>Edit</a>
        <a class='cta cta-yellow fork' href='#' data-index='<%= index %>'>Fork</a>
      </p>
    </div>
    <p><a href='#' class='jqmClose'>Close</a></p>
  </div>
"
class SquelchView extends Backbone.View
  squelch: (event) =>
    event.preventDefault()
    event.stopPropagation()
    event_is_touch = event.type.substring(0, "touch".length) == "touch"
    if @is_touch and not event_is_touch
      return true
    @is_touch = event_is_touch
    return false

class Gallery extends SquelchView
  template: _.template(gallery_template)
  gif_modal_template: _.template(gif_modal_template)
  events:
    'click .gif': 'modal'
    'touchstart .gif': 'modal'
    'click .edit': 'edit'
    'touchstart .edit': 'edit'
    'click .fork': 'fork'
    'touchstart .fork': 'fork'
    'click .new': 'add'
    'touchstart .new': 'add'

  add: (event) =>
    return false if @squelch(event)
    app.navigate("?q=A", trigger: true)
    return false

  edit: (event) =>
    return false if @squelch(event)
    gif = GIFS[parseInt($(event.currentTarget).attr("data-index"))]
    app.navigate("?q=#{gif.q}&id=#{gif.id}", trigger: true)
    @box.jqm().jqmHide()
    return false

  fork: (event) =>
    return false if @squelch(event)
    gif = GIFS[parseInt($(event.currentTarget).attr("data-index"))]
    app.navigate("?q=#{gif.q}", trigger: true)
    @box.jqm().jqmHide()
    return false

  render: =>
    @$el.html(@template(gifs: GIFS))

  modal: (event) =>
    index = parseInt($(event.currentTarget).attr("data-index"))
    gif = GIFS[index]
    @box = $(@gif_modal_template(gif: gif, index: index))
    @$el.append(@box.hide())
    $("input", @box).on "focus", -> $(this).select()
    @box.jqm({
      trigger: false
      onHide: (hash) =>
        hash.o.remove()
        @box.remove()
    }).jqmShow()
    return false


class Canvas extends SquelchView
  tagName: "canvas"
  cell_size: 64
  events:
    'touchstart': 'start'
    'touchmove':  'draw'
    'mousedown':  'start'
    'mousemove':  'draw'

  initialize: (options={}) ->
    @frame = options.frame
    @show_grid = if options.show_grid? then options.show_grid else true

    # Events
    @mouse_is_down = false
    $(window).on "mouseup", @stop
    $(window).on "touchend", @stop

    # Canvas
    @height = @cell_size * PXL.height
    @width = @cell_size * PXL.width
    @$el.attr { width: @width, height: @height }
    @ctx = @el.getContext('2d')
    @ctx.strokeStyle = "#ccc"
    @ctx.fillStyle = "#000"
    @ctx.lineWidth = 1

  remove: () ->
    $(window).off "mouseup", @stop
    $(window).off "touchend", @stop

  set_frame: (frame) ->
    @frame = frame
    @render()

  render_grid: =>
    # cols
    for i in [0...PXL.width]
      @ctx.beginPath()
      @ctx.moveTo(i * @cell_size, 0)
      @ctx.lineTo(i * @cell_size, @height)
      @ctx.stroke()
    # rows 
    for i in [0...PXL.height]
      @ctx.beginPath()
      @ctx.moveTo(0, i * @cell_size)
      @ctx.lineTo(@width, i * @cell_size)
      @ctx.stroke()

  render: =>
    for y in [0...@frame.length]
      for x in [0...@frame[y].length]
        @draw_bit({x, y})

  draw_bit: (coords) =>
    @ctx.fillStyle = if @frame[coords.y][coords.x] then "black" else "white"
    @ctx.fillRect(coords.x * @cell_size, coords.y * @cell_size, @cell_size, @cell_size)
    if @show_grid
      @ctx.strokeRect(coords.x * @cell_size, coords.y * @cell_size, @cell_size, @cell_size)

  get_grid_pos: (event) =>
    pos = @$el.offset()
    width = @$el.width()
    height = @$el.height()
    if @is_touch
      clientX = event.originalEvent.touches[0].clientX
      clientY = event.originalEvent.touches[0].clientY
    else
      clientX = event.clientX
      clientY = event.clientY
    x = Math.floor((clientX - pos.left) / width * PXL.width)
    y = Math.floor((clientY - pos.top) / height * PXL.height)
    if x>= 0 and x < PXL.width and y >=0 and y < PXL.height
      return {x, y}
    return null

  start: (event) =>
    return false if @squelch(event)
    @mouse_is_down = true
    coords = @get_grid_pos(event)
    if coords
      @_operation = if @frame[coords.y][coords.x] == 0 then 1 else 0
      @frame[coords.y][coords.x] = @_operation
      @draw_bit(coords)
    

  stop: (event) =>
    return false if @squelch(event)
    if @mouse_is_down
      @mouse_is_down = false
      @trigger "change", this

  draw: (event) =>
    return false if @squelch(event)
    if @mouse_is_down
      coords = @get_grid_pos(event)
      if coords
        @frame[coords.y][coords.x] = @_operation
        @draw_bit(coords)

editor_template = "
<div class='editor'>
  <div class='left-side'>
    <div class='nav'>
      <ul>
        <li><a href='#' class='previous-link cta cta-green'>Prev</a></li>
        <li>
          <div style='padding-top: 16px'>
            Frame
            <span class='frame-num'></span> /
            <span class='frame-total'></span>
          </div>
        </li>
        <li>
          <a href='#' class='next-link cta cta-green'>Next</a>
        </li>
      </ul>
      <div style='clear: both;'></div>
    </div>
    <div class='canvas-holder'></div>
    <div class='add-drop'>
      <a href='#' class='remove-link cta cta-red'>Remove</a>
      <a href='#' class='add-link cta cta-blue'>Add frame</a>
      <div style='clear: both;'>
        <a href='#' style='width: 100%; text-align: center;'
           class='save-link cta cta-yellow'>Save</a>
      </div>
    </div>
  </div>
  <div class='right-side'>
    <div class='preview-holder'>
      <div class='frames'></div>
      <div class='animation' style='margin-top: 5px;'></div>
    </div>
  </div>
  <div style='clear: both;'></div>
</div>
"
post_save_template = "
  <div class='jqmWindow'>
    <h1>W00t</h1>
    <div style='text-align: center;'>
      <p>Here is your gif:</p>
      <p><img src='<%= gif %>' /></p>
      <input size='40' type='text' readonly value='<%= window.location.protocol + '://' + window.location.host + gif %>' />
      <p>
        <a class='cta cta-yellow jqmClose' href='#'>close</a>
        <a class='cta cta-blue gallery' href='#'>Show gallery</a>
      </p>
    </div>
  </div>
"

class Editor extends SquelchView
  template: _.template(editor_template)
  post_save_template: _.template(post_save_template)
  events:
    'click           .next-link': 'next_frame'
    'touchstart      .next-link': 'next_frame'
    'click       .previous-link': 'prev_frame'
    'touchstart  .previous-link': 'prev_frame'
    'click            .add-link': 'add_frame'
    'touchstart       .add-link': 'add_frame'
    'click         .remove-link': 'remove_frame'
    'touchstart    .remove-link': 'remove_frame'
    'click           .save-link': 'save'
    'touchstart     a.save-link': 'save'
    'click             .gallery': 'gallery'
    'touchstart        .gallery': 'gallery'

  initialize: (options) ->
    @pxl = options.pxl
    @frames = decode_pxl(@pxl)
    @current_frame = 0
    @preview_canvases = []

  remove: =>
    clearInterval(@animationInterval)
    @canvas.remove()
    @animation.remove()
    for c in @preview_canvases
      c.remove()
    @$el.remove()

  render: =>
    @$el.html @template(slug: @pxl)
    if window.CANVAS_TARGET_HEIGHT?
      @$(".canvas-holder").height(window.CANVAS_TARGET_HEIGHT).width(window.CANVAS_TARGET_HEIGHT)
    @canvas = new Canvas()
    @$(".canvas-holder").html(@canvas.el)

    #
    # animation
    #
    @animation = new Canvas(show_grid: false)
    @animation_frame = @current_frame
    @$(".animation").html(@animation.el)
    @animation_interval = setInterval =>
      @animation_frame = (@animation_frame + 1) % @frames.length
      @animation.set_frame(@frames[@animation_frame])
    , 200

    #
    # Preview frames
    #
    for frame in @frames
      canvas = new Canvas(frame: frame, show_grid: false)
      @preview_canvases.push(canvas)
      @$(".frames").append(canvas.el)
      canvas.render()
      canvas.on "change", =>
        @canvas.render()

    @canvas.on "change", =>
      @update_url()
      @preview_canvases[@current_frame].render()
    #
    # And go!
    #
    @set_frame(@current_frame)

    #
    # Set up auto sizing
    #
    resize = =>
      max_height = $(window).height()
      max_width = $(window).width()
      max_canvas_height = max_height - @$(".add-drop").height() - @$(".nav").height()
      max_canvas_width  = max_width - @$(".right-side").width()
      target_height = Math.max(280, Math.min(max_canvas_height, max_canvas_width) - 20)
      # Cache this to make it render faster on back/forward nav.
      window.CANVAS_TARGET_HEIGHT = target_height
      @$(".canvas-holder").height(target_height).width(target_height)
    setTimeout(resize, 100)
    $(window).on("resize", resize)


  set_frame: (frame_num) =>
    if frame_num != @current_frame
      @$(".nav li").effect("highlight")
    @preview_canvases[@current_frame]?.$el.removeClass("current")
    @current_frame = frame_num

    @$(".next-link, .previous-link, .remove-link").toggleClass("cta-disabled", @frames.length <= 1)
    @$(".add-link").toggle(@frames.length < PXL.max_num_frames)

    @$(".frame-num").html(@current_frame + 1)
    @$(".frame-total").html(@frames.length)
    @canvas.set_frame(@frames[@current_frame])
    @preview_canvases[@current_frame].$el.addClass("current")

  next_frame: (event) =>
    return false if @squelch(event)
    @set_frame (@current_frame + 1) % @frames.length
    return false

  prev_frame: (event) =>
    return false if @squelch(event)
    @set_frame (@current_frame - 1 + @frames.length) % @frames.length
    return false

  add_frame: (event) =>
    return false if @squelch(event)
    # Create a copy of the current frame.
    copy = []
    for row in @frames[@current_frame]
      copy_row = []
      for bit in row
        copy_row.push(bit)
      copy.push(copy_row)
    # Add it to our array of frames in the place of the current.
    @frames.splice(@current_frame + 1, 0, copy)

    # Create a preview element
    preview = new Canvas(frame: copy)
    @preview_canvases.splice(@current_frame + 1, 0, preview)
    $(@$(".frames canvas")[@current_frame]).after(preview.el)
    preview.render()

    # Set the view to this frame.
    @set_frame(@current_frame + 1)
    @update_url()
    return false

  remove_frame: (event) =>
    return false if @squelch(event)
    @frames.splice(@current_frame, 1)
    preview = @preview_canvases.splice(@current_frame, 1)[0]
    preview.$el.remove()
    if @current_frame < @frames.length
      @set_frame(@current_frame)
    else
      @set_frame(@frames.length - 1)
    @update_url()
    return false

  save: (event) =>
    return false if @squelch(event)
    $.ajax {
      url: '/save',
      type: 'POST',
      data: {id: get_query_param("id"), q: @pxl},
      success: (data) =>
        id = get_query_param("id")
        id = parseInt(id) if id?
        data.gif += "?nocache=" + (new Date()).getTime()
        if not id?
          GIFS.splice(0, 0, data)
        else
          for gif in GIFS
            if gif.id == id
              gif.q = data.q
              gif.gif = data.gif
              break

        @modal = $(@post_save_template(gif: data.gif))
        $("input", @modal).on "focus", -> $(this).select()
        @$el.append(@modal.hide())
        $(@modal).jqm({
          trigger: false
          onHide: (hash) =>
            @modal.remove()
            hash.o.remove()
        }).jqmShow()
      error: (err) =>
        console.err err
        alert("Oh snap! Server error.")
    }
    return false

  update_url: =>
    id = get_query_param("id")
    id = parseInt(id) if id?
    @pxl = encode_pxl(@frames)
    url = "?q=#{@pxl}"
    if id?
      url += "&id=#{id}"
    if url != window.location.search
      app.navigate("/#{url}", {trigger: false})

  gallery: (event) =>
    event.preventDefault()
    app.navigate("/", {trigger: true})
    @modal.jqm().jqmHide()
    return false

class Router extends Backbone.Router
  routes: {
    '': 'gallery'
    '?*qs': 'editor'
  }

  editor: ->
    @gallery_view?.remove()
    @editor_view = new Editor(pxl: get_query_param("q"))
    $("#app").html @editor_view.el
    @editor_view.render()

  gallery: ->
    @editor_view?.remove()
    @gallery_view = new Gallery()
    $("#app").html @gallery_view.el
    @gallery_view.render()

app = new Router()
Backbone.history.start(pushState: true, silent: false)
