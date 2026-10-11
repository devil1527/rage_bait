class_name TouchButton
extends TextureButton

## Multitouch-capable on-screen gameplay button for Retro Rage Arcade.
## Tracks independent touch indices so multiple buttons can be pressed
## and held simultaneously without conflicting or canceling each other.

signal touch_down
signal touch_up

@export var action_name: String = ""
@export var touch_margin: float = 14.0
@export var drag_margin: float = 30.0

var touch_index: int = -1
var is_active_pressed: bool = false

var _base_normal_tex: Texture2D
var _base_pressed_tex: Texture2D
var _base_modulate: Color = Color.WHITE

func _ready() -> void:
	# Ignore GUI mouse routing to prevent Godot's single-pointer BaseButton
	# emulation from interfering with multi-touch tracking.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base_normal_tex = texture_normal
	_base_pressed_tex = texture_pressed
	_base_modulate = modulate

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if get_tree().paused:
		reset()
		return
	if GameManager and not GameManager.is_gameplay_active:
		reset()
		return

	if event is InputEventScreenTouch:
		_process_screen_touch(event)
	elif event is InputEventScreenDrag:
		_process_screen_drag(event)
	elif event is InputEventMouseButton:
		_process_mouse_button(event)
	elif event is InputEventMouseMotion:
		_process_mouse_motion(event)

func _process_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if touch_index == -1 and _hit_test(event.position, touch_margin):
			touch_index = event.index
			_set_pressed(true)
			get_viewport().set_input_as_handled()
	else:
		if event.index == touch_index:
			touch_index = -1
			_set_pressed(false)
			get_viewport().set_input_as_handled()

func _process_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index == touch_index:
		# Released if dragged too far outside
		if not _hit_test(event.position, drag_margin):
			touch_index = -1
			_set_pressed(false)
	elif touch_index == -1:
		# Can claim touch if finger drags into this button
		if _hit_test(event.position, touch_margin):
			touch_index = event.index
			_set_pressed(true)
			get_viewport().set_input_as_handled()

func _process_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if touch_index == -1 and _hit_test(event.position, touch_margin):
				touch_index = -99  # Special mouse index
				_set_pressed(true)
				get_viewport().set_input_as_handled()
		else:
			if touch_index == -99:
				touch_index = -1
				_set_pressed(false)
				get_viewport().set_input_as_handled()

func _process_mouse_motion(event: InputEventMouseMotion) -> void:
	if touch_index == -99:
		if not _hit_test(event.position, drag_margin):
			touch_index = -1
			_set_pressed(false)
	elif touch_index == -1 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if _hit_test(event.position, touch_margin):
			touch_index = -99
			_set_pressed(true)
			get_viewport().set_input_as_handled()

func _hit_test(screen_pos: Vector2, margin: float) -> bool:
	var canvas_xform := get_global_transform_with_canvas()
	var local_pos := canvas_xform.affine_inverse() * screen_pos
	var hit_rect := Rect2(Vector2.ZERO, size)
	if margin > 0.0:
		hit_rect = hit_rect.grow(margin)
	return hit_rect.has_point(local_pos)

func _set_pressed(pressed: bool) -> void:
	if is_active_pressed == pressed:
		return
	is_active_pressed = pressed

	# Update visual texture immediately
	if _base_pressed_tex:
		texture_normal = _base_pressed_tex if pressed else _base_normal_tex

	# Responsive, instant visual scale & highlight feedback without input delay
	pivot_offset = size * 0.5
	var tween := create_tween()
	if pressed:
		tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.04).set_trans(Tween.TRANS_QUAD)
		var pressed_col := Color(_base_modulate.r * 1.2, _base_modulate.g * 1.2, _base_modulate.b * 1.2, _base_modulate.a)
		tween.parallel().tween_property(self, "modulate", pressed_col, 0.04)
	else:
		tween.tween_property(self, "scale", Vector2.ONE, 0.06).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(self, "modulate", _base_modulate, 0.06)

	if pressed:
		if action_name != "":
			Input.action_press(action_name)
		touch_down.emit()
		button_down.emit()
	else:
		if action_name != "":
			Input.action_release(action_name)
		touch_up.emit()
		button_up.emit()

func reset() -> void:
	if touch_index != -1 or is_active_pressed:
		touch_index = -1
		_set_pressed(false)
	scale = Vector2.ONE
	modulate = _base_modulate

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_PAUSED:
		reset()

func _exit_tree() -> void:
	reset()
