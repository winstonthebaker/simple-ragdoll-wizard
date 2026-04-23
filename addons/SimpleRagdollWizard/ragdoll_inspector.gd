@tool
extends EditorInspectorPlugin
func _can_handle(object: Object) -> bool:
	return object is RagdollGenerator

func _parse_begin(object: Object) -> void:

	var generate_button := Button.new()
	generate_button.text = "Generate Ragdoll"
	generate_button.pressed.connect(
		func(): object.call("generate_ragdoll")
	)
	add_custom_control(generate_button)
	
	var mirror_button := Button.new()
	mirror_button.text = "Mirror Colliders Left to Right"
	mirror_button.pressed.connect(
		func():object.call("symmetrize")
	)
	add_custom_control(mirror_button)
