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
    <a href='#' class='cta cta-blue new'>New</a>
    <% for (var i = 0; i < gifs.length; i++) { %>
      <a class='gif' href='' data-index='<%= i %>'><img src='<%= gifs[i].gif %>' /></a>
    <% } %>
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
class Gallery extends Backbone.View
  template: _.template(gallery_template)
  gif_modal_template: _.template(gif_modal_template)
  events:
    'click .gif': 'modal'
    'click .edit': 'edit'
    'click .fork': 'fork'
    'click .new': 'add'

  add: (event) =>
    app.navigate("?q=A", trigger: true)
    return false

  edit: (event) =>
    gif = GIFS[parseInt($(event.currentTarget).attr("data-index"))]
    app.navigate("?q=#{gif.q}&id=#{gif.id}", trigger: true)
    @box.jqm().jqmHide()
    return false

  fork: (event) =>
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
    'touchmove .pixel':  'draw'
    'mousedown .pixel':  'start'
    'mouseover .pixel':  'draw'

  initialize: (options={}) ->
    @frame = options.frame
    @mouse_is_down = false
    $(window).on "mouseup", @stop
    $(window).on "touchend", @stop

  remove: () ->
    $(window).off "mouseup", @stop
    $(window).off "touchend", @stop

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
    if event.type == "touchstart"
      @is_touch = true
    el = $(event.currentTarget)
    @_operation = not el.hasClass("active")
    @toggle_bit(el)
    @mouse_is_down = true

  stop: (event) =>
    if @mouse_is_down
      @mouse_is_down = false
      @trigger "change", this

  draw: (event) =>
    if @is_touch
        if event.type == "mousemove"
          return
        target = document.elementFromPoint(
            event.originalEvent.changedTouches[0].pageX,
            event.originalEvent.changedTouches[0].pageY
        )
    else
        target = event.currentTarget
    if @mouse_is_down
      @toggle_bit($(target))

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

class Editor extends Backbone.View
  template: _.template(editor_template)
  post_save_template: _.template(post_save_template)
  events:
    'click a.next-link':     'next_frame'
    'click a.previous-link': 'prev_frame'
    'click a.add-link':      'add_frame'
    'click a.remove-link':   'remove_frame'
    'click a.save-link':     'save'
    'click a.gallery':       'gallery'

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
    @canvas = new Canvas()
    @$(".canvas-holder").html(@canvas.el)

    #
    # animation
    #
    @animation = new Canvas()
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
      canvas = new Canvas(frame: frame)
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

  next_frame: =>
    @set_frame (@current_frame + 1) % @frames.length
    return false

  prev_frame: =>
    @set_frame (@current_frame - 1 + @frames.length) % @frames.length
    return false

  add_frame: =>
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

  remove_frame: =>
    @frames.splice(@current_frame, 1)
    preview = @preview_canvases.splice(@current_frame, 1)[0]
    preview.$el.remove()
    if @current_frame < @frames.length
      @set_frame(@current_frame)
    else
      @set_frame(@frames.length - 1)
    @update_url()
    return false

  save: =>
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

  gallery: =>
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
