extends Area3D
## A big floor button. Step on it (robot) or land on it (drone) to press it.
## Whatever is connected to `pressed` happens - usually a door opens.

signal pressed

@export var color := Color("ff5a5a")

var is_pressed := false
var _cap: MeshInstance3D


func _ready() -> void:
	add_to_group("button")
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.75
	base_mesh.bottom_radius = 0.75
	base_mesh.height = 0.12
	base.mesh = base_mesh
	var base_mat := StandardMaterial3D.new()
	base_mat.albedo_color = Color("3a3f4a")
	base.material_override = base_mat
	base.position.y = 0.06
	add_child(base)

	_cap = MeshInstance3D.new()
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.55
	cap_mesh.bottom_radius = 0.6
	cap_mesh.height = 0.25
	_cap.mesh = cap_mesh
	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = color
	cap_mat.emission_enabled = true
	cap_mat.emission = color
	cap_mat.emission_energy_multiplier = 0.8
	_cap.material_override = cap_mat
	_cap.position.y = 0.12 + 0.125
	add_child(_cap)

	# tall enough that a hovering drone counts as "on" the button
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.7
	cyl.height = 1.6
	shape.shape = cyl
	shape.position.y = 0.8
	add_child(shape)

	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if is_pressed:
		return
	if body.is_in_group("player") or body.is_in_group("drone"):
		press()


func press() -> void:
	if is_pressed:
		return
	is_pressed = true
	var tween := create_tween()
	tween.tween_property(_cap, "position:y", 0.12 + 0.04, 0.15)
	var mat: StandardMaterial3D = _cap.material_override
	mat.albedo_color = Color("6ad14f")
	mat.emission = Color("6ad14f")
	pressed.emit()
