extends Node3D
## A dying ceiling lamp: dim, buzzing, flickers, sometimes goes out completely.

@export var color := Color("9fffb0")
@export var energy := 1.1
@export var light_range := 5.5
@export var flicker := 0.5        # 0 = steady, 1 = very jittery
@export var blackout_chance := 0.004   # per frame chance it dies for a moment

var _light: OmniLight3D
var _bulb: MeshInstance3D
var _bulb_mat: StandardMaterial3D
var _dark_for := 0.0
var _time := 0.0


func _ready() -> void:
	add_to_group("lamp")
	_light = OmniLight3D.new()
	_light.light_color = color
	_light.light_energy = energy
	_light.omni_range = light_range
	_light.shadow_enabled = true
	_light.position.y = -0.15
	add_child(_light)

	var fixture := MeshInstance3D.new()
	var fixture_mesh := BoxMesh.new()
	fixture_mesh.size = Vector3(1.2, 0.1, 0.4)
	fixture.mesh = fixture_mesh
	var fixture_mat := StandardMaterial3D.new()
	fixture_mat.albedo_color = Color("222222")
	fixture.material_override = fixture_mat
	add_child(fixture)

	_bulb = MeshInstance3D.new()
	var bulb_mesh := BoxMesh.new()
	bulb_mesh.size = Vector3(1.0, 0.06, 0.25)
	_bulb.mesh = bulb_mesh
	_bulb_mat = StandardMaterial3D.new()
	_bulb_mat.albedo_color = color
	_bulb_mat.emission_enabled = true
	_bulb_mat.emission = color
	_bulb_mat.emission_energy_multiplier = 2.0
	_bulb.material_override = _bulb_mat
	_bulb.position.y = -0.07
	add_child(_bulb)


func _process(delta: float) -> void:
	_time += delta
	if _dark_for > 0.0:
		_dark_for -= delta
		_light.light_energy = 0.0
		_bulb_mat.emission_energy_multiplier = 0.0
		return
	if randf() < blackout_chance:
		_dark_for = randf_range(0.1, 1.5)
	var jitter := 1.0 - flicker * (0.5 + 0.5 * sin(_time * 37.0) * sin(_time * 11.3)) * randf()
	_light.light_energy = energy * jitter
	_bulb_mat.emission_energy_multiplier = 2.0 * jitter
