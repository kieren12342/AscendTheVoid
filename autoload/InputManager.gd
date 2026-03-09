extends Node

signal drag_started(position: Vector2, source: String)
signal drag_moved(position: Vector2, source: String)
signal drag_ended(position: Vector2, source: String)
signal tap(position: Vector2)

var _dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _drag_threshold: float = 10.0
var _touch_index: int = -1

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag_start = event.position
				_dragging = false
			else:
				if _dragging:
					drag_ended.emit(event.position, "mouse")
					_dragging = false
				else:
					tap.emit(event.position)
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not _dragging and event.position.distance_to(_drag_start) > _drag_threshold:
				_dragging = true
				drag_started.emit(_drag_start, "mouse")
			if _dragging:
				drag_moved.emit(event.position, "mouse")
	elif event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_drag_start = event.position
			_dragging = false
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			if _dragging:
				drag_ended.emit(event.position, "touch")
				_dragging = false
			else:
				tap.emit(event.position)
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			if not _dragging and event.position.distance_to(_drag_start) > _drag_threshold:
				_dragging = true
				drag_started.emit(_drag_start, "touch")
			if _dragging:
				drag_moved.emit(event.position, "touch")
