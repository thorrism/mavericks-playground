extends StaticBody3D
## A coloured sliding door. Call open() and it grinds up out of the way (you can hear it
## from across the school, so you know a button did something). A TIMED door (close_after > 0)
## slams back down after that many seconds - the level takes care of the countdown and calls close().

@export var color := Color("ff5a5a")
@export var size := Vector3(2.0, 2.8, 0.4)
@export var locked_symbol := "?"
@export var close_after := 0.0   # seconds it stays open; 0 = for good

signal opened
signal closed

var is_open := false
var _mesh: MeshInstance3D
var _shape: CollisionShape3D
var _tween: Tween


func _ready() -> void:
	add_to_group("door")
	var box := BoxMesh.new()
	box.size = size
	_mesh = MeshInstance3D.new()
	_mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.35
	_mesh.material_override = mat
	_mesh.position.y = size.y / 2.0
	add_child(_mesh)

	# a lighter stripe so it reads as a door, not a wall
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()
	stripe_mesh.size = Vector3(size.x * 0.6, size.y * 0.6, size.z + 0.04)
	stripe.mesh = stripe_mesh
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = color.lightened(0.45)
	stripe.material_override = stripe_mat
	stripe.position.y = size.y / 2.0
	_mesh.add_child(stripe)

	_shape = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	_shape.shape = shape
	_shape.position.y = size.y / 2.0
	add_child(_shape)


func open() -> void:
	if is_open:
		return
	is_open = true
	_shape.set_deferred("disabled", true)
	_grind(1.0)
	opened.emit()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_mesh, "position:y", size.y * 1.5 + 0.2, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Slams shut again (timed doors). Solid straight away, so nobody gets stuck half-way through.
func close() -> void:
	if not is_open:
		return
	is_open = false
	_shape.set_deferred("disabled", false)
	_grind(0.7)
	closed.emit()
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_mesh, "position:y", size.y / 2.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _grind(pitch: float) -> void:
	var sound := AudioStreamPlayer3D.new()
	sound.name = "OpenSound" if pitch >= 1.0 else "SlamSound"
	sound.stream = Sfx.get_sound("door")
	sound.unit_size = 10.0
	sound.max_distance = 80.0
	sound.volume_db = 4.0 if pitch >= 1.0 else 8.0
	sound.pitch_scale = pitch
	sound.position.y = size.y / 2.0
	sound.autoplay = true
	sound.finished.connect(sound.queue_free)
	add_child(sound)
