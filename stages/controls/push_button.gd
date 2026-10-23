@tool
class_name PushButton
extends InkDrawing
## A round push button in ink: a cap coloured in with crayon inside a pen line, sitting in a base.
## While it is live, pointing at it lifts the cap and clicking it presses it; a control elsewhere can
## light it too. Its [ButtonLook] sets the colour in the cap and the mark on it, and it can carry a word,
## such as "press". The cap sinks behind the front of the base when pressed, with a click.
## Its origin is the middle of the bottom of its base.

## Emitted when the pointer moves onto or off the button while it is live.
signal hover_changed(hovered: bool)
## Emitted when the player clicks the button while it is live.
signal clicked

## How the button looks. Empty draws a plain one.
@export var look: ButtonLook:
	set(value):
		look = value
		queue_redraw()
## The word on the cap. Empty for none.
@export var text := "":
	set(value):
		text = value
		_place_word()
## The label that shows [member text].
@export var word: Label

@export_group("Shape")
## Width and height of the base the cap sits in.
@export var base_size := Vector2(200.0, 36.0):
	set(value):
		base_size = value
		_reshape()
## Radius of the base's rounded corners.
@export_range(0.0, 40.0, 0.5) var base_corner := 13.0:
	set(value):
		base_corner = value
		queue_redraw()
## Radius of the round cap.
@export_range(10.0, 200.0, 0.5) var cap_radius := 70.0:
	set(value):
		cap_radius = value
		_reshape()
## How deep the cap sits into the base, as a share of the base's height.
@export_range(0.0, 1.0, 0.01) var cap_seat := 0.3:
	set(value):
		cap_seat = value
		_reshape()

@export_group("Crayon")
## Angle of the crayon strokes in the cap, in degrees.
@export_range(-90.0, 90.0, 0.5) var hatch_angle := -32.0:
	set(value):
		hatch_angle = value
		queue_redraw()
## Distance between neighbouring crayon strokes.
@export_range(2.0, 40.0, 0.5) var hatch_spacing := 9.0:
	set(value):
		hatch_spacing = value
		queue_redraw()
## Width of the crayon strokes, as a multiple of the line width.
@export_range(0.1, 3.0, 0.05) var hatch_width := 1.3:
	set(value):
		hatch_width = value
		queue_redraw()
## How far inside the cap's outline the crayon stays.
@export_range(0.0, 30.0, 0.5) var hatch_inset := 7.0:
	set(value):
		hatch_inset = value
		queue_redraw()
## How strongly a flat wash under the crayon takes the colour, so no bare paper shows between strokes.
@export_range(0.0, 1.0, 0.01) var under_wash := 0.16:
	set(value):
		under_wash = value
		queue_redraw()

@export_group("Marks")
## Radius of the ring mark, as a share of the cap's radius.
@export_range(0.05, 0.9, 0.01) var ring_size := 0.42:
	set(value):
		ring_size = value
		queue_redraw()
## Radius of the dot mark, as a share of the cap's radius.
@export_range(0.02, 0.6, 0.01) var dot_size := 0.16:
	set(value):
		dot_size = value
		queue_redraw()
## Height of the money mark, as a share of the cap's radius.
@export_range(0.1, 1.5, 0.01) var money_size := 0.9:
	set(value):
		money_size = value
		queue_redraw()
## Width of the marks' lines, as a multiple of the line width.
@export_range(0.2, 3.0, 0.05) var mark_width := 1.25:
	set(value):
		mark_width = value
		queue_redraw()
## Palette role of the marks.
@export var mark_role := &"ink":
	set(value):
		mark_role = value
		queue_redraw()

@export_group("Pointing")
## The area that catches the pointer, in this node's space.
@export var hit_area := Rect2(-110.0, -190.0, 220.0, 200.0)
## How far the cap rises while it is pointed at or lit.
@export_range(0.0, 30.0, 0.5) var lift_height := 6.0
## Width of the cap's line while it is pointed at or lit, as a multiple of its resting width.
@export_range(1.0, 3.0, 0.05) var lifted_width := 1.4
## Seconds the cap takes to rise or settle.
@export_range(0.0, 1.0, 0.01) var lift_duration := 0.12

@export_group("Pressing")
## How far the cap sinks into the base when pressed.
@export_range(0.0, 80.0, 0.5) var press_travel := 18.0
## Seconds the cap takes to go down.
@export_range(0.01, 1.0, 0.01) var press_down_time := 0.07
## Seconds it stays down.
@export_range(0.0, 1.0, 0.01) var press_hold := 0.06
## Seconds it takes to spring back up.
@export_range(0.01, 2.0, 0.01) var press_up_time := 0.3
## Played as the cap goes down.
@export var press_sound: SoundCue = preload("res://game/audio/cues/button_press.tres")

@export_group("Word")
## Size of the word's letters.
@export_range(8, 160) var word_size := 40:
	set(value):
		word_size = value
		_place_word()
## Palette role of the word.
@export var word_role := &"ink":
	set(value):
		word_role = value
		_place_word()

## How far down the cap is: 0 is up, 1 is pressed all the way.
var depth := 0.0:
	set(value):
		depth = value
		_reshape()
## How far the cap is lifted: 0 is resting, 1 is lifted all the way.
var lift := 0.0:
	set(value):
		lift = value
		_reshape()
## Whether the button answers the pointer.
var live := false:
	set(value):
		live = value
		if not live:
			_set_hovered(false)
## Whether the button shows as lifted because its option is pointed at elsewhere.
var highlighted := false:
	set(value):
		highlighted = value
		_refresh_lift()

## The money mark, a hand-drawn dollar sign, as a share of the mark's height around the cap's middle.
const _MONEY_S := [Vector2(0.3, -0.3), Vector2(0.02, -0.42), Vector2(-0.28, -0.3), Vector2(-0.22, -0.06),
		Vector2(0.02, 0.0), Vector2(0.26, 0.08), Vector2(0.3, 0.3), Vector2(0.0, 0.42), Vector2(-0.32, 0.3)]
const _MONEY_BAR := [Vector2(0.0, -0.56), Vector2(0.0, 0.56)]
## Where the cap's outline starts, in radians, so its seam sits up and to the left.
const _CAP_START := -PI * 0.7

var _hovered := false
var _lift_tween: Tween
var _press_tween: Tween


func _ready() -> void:
	super._ready()
	_place_word()


func _unhandled_input(event: InputEvent) -> void:
	if not live or not event is InputEventMouse:
		return
	var over := hit_area.has_point((make_input_local(event) as InputEventMouse).position)
	if event is InputEventMouseMotion:
		_set_hovered(over)
	elif over and event.is_action_pressed(&"pick"):
		get_viewport().set_input_as_handled()
		clicked.emit()


## Where the middle of the cap is now, in this node's space.
func cap_middle() -> Vector2:
	return Vector2(0.0, -base_size.y - cap_radius + base_size.y * cap_seat + depth * press_travel - lift * lift_height)


## The middle of the cap on the canvas, where a pointer would press it.
func press_point() -> Vector2:
	return get_global_transform_with_canvas() * cap_middle()


## Presses the button: the cap sinks into the base and springs back up.
func press() -> void:
	live = false
	highlighted = false
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	Sfx.play(press_sound)
	_press_tween = create_tween()
	_press_tween.tween_property(self, ^"depth", 1.0, press_down_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_press_tween.tween_interval(press_hold)
	_press_tween.tween_property(self, ^"depth", 0.0, press_up_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await _press_tween.finished


func _build_lines(style: InkStyle, palette: InkPalette) -> Array[InkLine]:
	var spacing := style.sample_spacing
	var color := palette.color(look.cap_role if look != null else &"secondary")
	var strength := look.wash if look != null else 0.5
	var middle := cap_middle()
	var lifted := _hovered or highlighted
	var lines: Array[InkLine] = []
	# The outline first, with a light wash, then the crayon colouring in over the wash.
	var cap := InkLine.along(InkBrush.ellipse(middle, Vector2.ONE * cap_radius, spacing, _CAP_START), palette.ink,
			lifted_width if lifted else 1.0, true)
	cap.fill = palette.paper.lerp(color, under_wash)
	lines.append(cap)
	var scribble := InkBrush.hatch_ellipse(middle, Vector2.ONE * cap_radius, deg_to_rad(hatch_angle), hatch_spacing, hatch_inset)
	if scribble.size() > 1:
		lines.append(InkLine.along(InkBrush.resample_polyline(scribble, spacing), Color(color, strength), hatch_width))
	lines.append_array(_mark_lines(middle, palette.color(mark_role), spacing))
	# The base goes in front, filled with paper, so a pressed cap sinks behind it.
	var base_rect := Rect2(-base_size.x * 0.5, -base_size.y, base_size.x, base_size.y)
	var base := InkLine.along(InkBrush.rounded_rect(base_rect, base_corner, spacing), palette.ink, 1.0, true)
	base.fill = palette.paper
	lines.append(base)
	return lines


func _mark_lines(middle: Vector2, color: Color, spacing: float) -> Array[InkLine]:
	var lines: Array[InkLine] = []
	match look.mark if look != null else ButtonLook.Mark.NONE:
		ButtonLook.Mark.RING:
			lines.append(InkLine.along(InkBrush.ellipse(middle, Vector2.ONE * cap_radius * ring_size, spacing * 0.5),
					color, mark_width, true))
		ButtonLook.Mark.DOT:
			lines.append(InkLine.dot(middle, cap_radius * dot_size, color))
		ButtonLook.Mark.MONEY:
			var height := cap_radius * money_size
			lines.append(InkLine.along(InkBrush.resample_smooth(_placed(_MONEY_S, middle, height), false, spacing * 0.5),
					color, mark_width))
			lines.append(InkLine.along(InkBrush.resample_polyline(_placed(_MONEY_BAR, middle, height), spacing * 0.5),
					color, mark_width))
	return lines


static func _placed(points: Array, middle: Vector2, height: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for point: Vector2 in points:
		out.append(middle + point * height)
	return out


func _set_hovered(hovered: bool) -> void:
	if hovered == _hovered:
		return
	_hovered = hovered
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hovered else Input.CURSOR_ARROW)
	_refresh_lift()
	hover_changed.emit(hovered)


func _refresh_lift() -> void:
	var target := 1.0 if (_hovered or highlighted) else 0.0
	if not is_inside_tree():
		lift = target
		return
	if _lift_tween != null and _lift_tween.is_valid():
		_lift_tween.kill()
	_lift_tween = create_tween()
	_lift_tween.tween_property(self, ^"lift", target, lift_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _reshape() -> void:
	queue_redraw()
	_place_word()


## Centres the word on the cap, in its colour.
func _place_word() -> void:
	if word == null:
		return
	word.text = text
	word.visible = not text.is_empty()
	word.add_theme_font_size_override(&"font_size", word_size)
	word.add_theme_color_override(&"font_color", InkPalette.get_default().color(word_role))
	word.reset_size()
	word.position = cap_middle() - word.size * 0.5


## The word goes with the button as it is drawn on or dissolves away.
func _draw() -> void:
	super._draw()
	if word != null:
		word.modulate.a = minf(reveal, 1.0 - dissolve)


func _apply_dissolve() -> void:
	super._apply_dissolve()
	if word != null:
		word.modulate.a = minf(reveal, 1.0 - dissolve)
