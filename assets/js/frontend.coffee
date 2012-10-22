#= require vendor/jquery
#= require vendor/underscore
#= require vendor/underscore-autoescape
#= require vendor/backbone
#= require flash
#= require serialize_pixel

class Router extends Backbone.Router
  routes:
    ':slug':    'editor'
    '':         'editor'

  editor: (slug="") ->
    editor = new Editor(pxl: slug)
    $("#app").html editor.el
    editor.render()

  gallery: (slug) ->
    gallery = new Gallery()
    $("#app").html gallery.el
    gallery.render()

canvas_template = "
  <% for (var y = 0; y < bits.length; y++) { %>
    <div class='row'>
    <% for (var x = 0; x < bits[y].length; x++) { %>
      <div class='pixel <%= bits[y][x] ? 'active' : '' %>'
           data-x='<%= x %>' data-y='<%= y %>'></div>
    <% } %>
    </div>
  <% } %>
"

class Canvas extends Backbone.View
  template: _.template(canvas_template)
  events:
    'touchstart .pixel': 'start'
    'mousedown .pixel':  'start'
    'mouseover .pixel':  'draw'
    'touchmove .pixel':  'draw'

  initialize: (options={}) ->
    @frame = options.frame
    @mouse_is_down = false
    $(window).on "mouseup", @stop
    $(window).on "touchend", @stop

  set_frame: (frame) ->
    @frame = frame
    @render()

  render: =>
    @$el.addClass("canvas")
    @$el.html @template(bits: @frame)

  toggle_bit: (el) =>
    @frame[parseInt(el.attr("data-y"))][parseInt(el.attr("data-x"))] = if @_operation then 1 else 0
    el.toggleClass("active", @_operation)

  start: (event) =>
    el = $(event.currentTarget)
    @_operation = not el.hasClass("active")
    @toggle_bit(el)
    @mouse_is_down = true

  stop: (event) =>
    @mouse_is_down = false
    @trigger "change", this

  draw: (event) =>
    if @mouse_is_down
      @toggle_bit($(event.currentTarget))

editor_template = "
<div class='editor'>
  <h1>Frame
    <span class='frame-num'></span> /
    <span class='frame-total'></span>
  </h1>
  <div class='nav'>
    <a href='#' class='previous-link cta cta-green'>Previous</a>
    <a href='#' class='next-link cta cta-green'>Next</a>
    <div style='clear: both;'></div>
  </div>
  <div class='canvas-holder'></div>
  <div class='add-drop'>
    <a href='#' class='remove-link cta cta-red'>Remove frame</a>
    <a href='#' class='add-link cta cta-blue'>Add frame</a>
    <div style='clear: both;'></div>
  </div>
  <div class='preview-holder'>
    <div class='frames'></div>
    <div class='animation'></div>
    <a class='permalink' href='<%= slug %>.gif'>GET GIF</a>
  </div>
</div>
"

class Editor extends Backbone.View
  template: _.template(editor_template)
  events:
    'click a.next-link':     'next'
    'click a.previous-link': 'prev'
    'click a.add-link':      'add'
    'click a.remove-link':   'remove'

  initialize: (options) ->
    @pxl = options.pxl
    @frames = decode_pxl(@pxl)
    @current_frame = 0
    @preview_canvases = []

  render: =>
    @$el.html @template(slug: @pxl)
    @canvas = new Canvas()
    @$(".canvas-holder").html(@canvas.el)

    #
    # animation
    #
    @animation = new Canvas()
    @animation_frame = @current_frame
    @$(".animation").html(@animation.el)
    setInterval =>
      @animation_frame = (@animation_frame + 1) % @frames.length
      @animation.set_frame(@frames[@animation_frame])
    , 200


    #
    # Preview frames
    #
    for frame, i in @frames
      canvas = new Canvas(frame: frame)
      @preview_canvases.push(canvas)
      @$(".frames").append(canvas.el)
      canvas.render()
      do (i) =>
        canvas.on "change", =>
          if i == @current_frame
            @canvas.render()

    @canvas.on "change", =>
      @update_url()
      @preview_canvases[@current_frame].render()
    #
    # And go!
    #
    @set_frame(@current_frame)


  set_frame: (frame_num) =>
    @preview_canvases[@current_frame]?.$el.removeClass("current")
    @current_frame = frame_num

    @$(".remove-link").toggle(@frames.length > 1)
    @$(".next-link").toggle(@frames.length > 1)
    @$(".previous-link").toggle(@frames.length > 1)
    @$(".add-link").toggle(@frames.length < PXL.max_num_frames)

    @$(".frame-num").html(@current_frame + 1)
    @$(".frame-total").html(@frames.length)
    @canvas.set_frame(@frames[@current_frame])
    @preview_canvases[@current_frame].$el.addClass("current")

  next: =>
    @set_frame (@current_frame + 1) % @frames.length
    return false

  prev: =>
    @set_frame (@current_frame - 1 + @frames.length) % @frames.length
    return false

  add: =>
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
    $(@$(".frames .canvas")[@current_frame]).after(preview.el)
    preview.render()

    # Set the view to this frame.
    @set_frame(@current_frame + 1)
    @update_url()
    return false

  remove: =>
    @frames.splice(@current_frame, 1)
    preview = @preview_canvases.splice(@current_frame, 1)[0]
    preview.$el.remove()
    if @current_frame < @frames.length
      @set_frame(@current_frame)
    else
      @set_frame(@frames.length - 1)
    @update_url()
    return false

  update_url: =>
    @pxl = encode_pxl(@frames)
    @$(".permalink").attr("href", "#{@pxl}.gif")
    app.navigate(@pxl, {trigger: false})

app = new Router()
Backbone.history.start(pushState: true)
