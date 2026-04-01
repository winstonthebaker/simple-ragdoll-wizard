@tool
class_name RagdollGenerator
extends Node

#region Export Vars
##The mass that every bone in the ragdoll is multiplied by. Be warned: this value may not actually be the total mass of all bones combined. 
@export var total_mass: float = 80.0

##The profile to use.
@export var ragdoll_profile: RagdollProfile = load("res://addons/SimpleRagdollWizard/RagdollProfiles/humanoid_ragdoll_profile.tres")

##If you don't wish to rename your bones, you can create a BoneMap resource using the "Retarget" option in your model's Advanced Import Settings. This value is ignored if it isn't set.
@export var bone_map: BoneMap

#endregion

#region Buttons

func generate_ragdoll() -> void:
	if not Engine.is_editor_hint():
		return

	var skeleton := _get_skeleton()
	if skeleton == null:
		return
	var simulator := PhysicalBoneSimulator3D.new()
	simulator.name = "PhysicalBoneSimulator3D"
	skeleton.add_child(simulator)
	simulator.owner = get_tree().edited_scene_root

	print("Generating ragdoll.")
	for bone_name in ragdoll_profile.ragdoll_bone_configs.keys():
		generate_bone(skeleton, simulator, bone_name)
		

func _is_left_bone(bone_name: String) -> bool:
	var n := bone_name.to_lower()
	return n.begins_with("left") or n.ends_with("left") \
		or n.begins_with("l.") or n.begins_with("l_") \
		or n.ends_with(".l") or n.ends_with("_l")

func symmetrize() -> void:
	var skeleton := _get_skeleton()
	if not skeleton:
		return
	var simulator := _get_simulator(skeleton)
	if not simulator:
		return

	var physical_bones: Array = _get_physical_bones(simulator)

	var bone_map_lookup := {}
	for bone in physical_bones:
		bone_map_lookup[bone.get("bone_name")] = bone

	for left_bone in physical_bones:
		var left_bone_name: String = left_bone.get("bone_name")
		if not _is_left_bone(left_bone_name):
			continue

		var mirrored_name := _mirror_bone_name(left_bone_name)
		if mirrored_name == left_bone_name:
			push_warning("Could not find mirror name for: " + left_bone_name)
			continue

		var right_bone = bone_map_lookup.get(mirrored_name)
		if not right_bone:
			push_warning("No matching bone found for mirror: " + mirrored_name)
			continue

		var left_col_shape: CollisionShape3D = _get_collision_shape(left_bone)
		var right_col_shape: CollisionShape3D = _get_collision_shape(right_bone)
		if left_col_shape and right_col_shape:
			print("Mirroring %s -> %s" % [left_bone_name, mirrored_name])
			right_col_shape.shape = left_col_shape.shape

			# Mirror position: flip X axis, preserve Y and Z
			var left_pos := left_col_shape.position
			right_col_shape.position = Vector3(-left_pos.x, left_pos.y, left_pos.z)

			# Mirror rotation: flip Y and Z euler angles, preserve X
			var left_rot := left_col_shape.rotation
			right_col_shape.rotation = Vector3(left_rot.x, -left_rot.y, -left_rot.z)
#endregion

#region Node Getters
func _get_skeleton() -> Skeleton3D:
	var parent := get_parent()
	if parent is Skeleton3D:
		return parent
	push_error("Ragdoll Generator must be a direct child of a Skeleton3D")
	return null

func _get_simulator(node: Node) -> PhysicalBoneSimulator3D:
	for child in node.get_children():
		if child is PhysicalBoneSimulator3D:
			return child
	return null

func _get_physical_bones(node: Node) -> Array:
	var physical_bones : Array = []
	for child in node.get_children():
		if child is PhysicalBone3D:
			physical_bones.append(child)
	return physical_bones

func _get_collision_shape(node: Node)-> CollisionShape3D:
	for child in node.get_children():
		if child is CollisionShape3D:
			return child
	return null
#endregion

#region Skeleton Helpers

## Returns the name of bone_id's first child, or "" if it has none.
func _first_child_name(skeleton: Skeleton3D, bone_id: int) -> String:
	var children := skeleton.get_bone_children(bone_id)
	return "" if children.is_empty() else skeleton.get_bone_name(children[0])

## Returns the position of next_bone_name in the local space of bone_id.
func _get_local_next_position(skeleton: Skeleton3D, bone_id: int, next_bone_id: int) -> Vector3:
	var bone_pose := skeleton.get_bone_global_pose(bone_id)
	var next_global = skeleton.get_bone_global_pose(next_bone_id).origin
	return (bone_pose.affine_inverse() * next_global)
	

#endregion

#region Physical Bone Construction Helpers


func _create_physical_bone(simulator: PhysicalBoneSimulator3D, bone_name: String, skeleton_bone_name = bone_name) -> PhysicalBone3D:
	var physical_bone := PhysicalBone3D.new()
	physical_bone.name = "PhysicalBone_" + bone_name
	physical_bone.set("bone_name", skeleton_bone_name)
	simulator.add_child(physical_bone)
	physical_bone.owner = get_tree().edited_scene_root
	return physical_bone

func _apply_body_offset(physical_bone: PhysicalBone3D, local_next: Vector3) -> void:
	if local_next.is_zero_approx():
		physical_bone.body_offset = Transform3D(Basis.IDENTITY, Vector3.ZERO)
		return
	
	# Build a basis oriented along local_next (bone's local Y axis direction)
	var up = local_next.normalized()
	var forward = Vector3.FORWARD if abs(up.dot(Vector3.FORWARD)) < 0.99 else Vector3.RIGHT
	var right = forward.cross(up).normalized()
	forward = up.cross(right).normalized()
	
	var oriented_basis = Basis(right, up, -forward)
	physical_bone.body_offset = Transform3D(oriented_basis, local_next * 0.5)

func _attach_collision(physical_bone: PhysicalBone3D, shape: Shape3D) -> void:
	var collision_shape := CollisionShape3D.new()
	collision_shape.name = "CollisionShape3D"
	collision_shape.shape = shape
	physical_bone.add_child(collision_shape)
	collision_shape.owner = get_tree().edited_scene_root

func _set_cone_joint(physical_bone: PhysicalBone3D, swing_span: float, twist_span: float) -> void:
	physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_CONE
	physical_bone.set("joint_constraints/swing_span", swing_span)
	physical_bone.set("joint_constraints/twist_span", twist_span)

func _set_6dof_joint(physical_bone: PhysicalBone3D, config: SixDOFJointConfig) -> void:
	physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_6DOF

	for axis in ["x", "y", "z"]:
		physical_bone.set("joint_constraints/%s/angular_limit_enabled" % axis, true)
		physical_bone.set("joint_constraints/%s/angular_spring_enabled" % axis, true)

	physical_bone.set("joint_constraints/x/angular_limit_upper", config.x_upper)
	physical_bone.set("joint_constraints/x/angular_limit_lower", config.x_lower)
	physical_bone.set("joint_constraints/x/angular_spring_stiffness", config.x_stiffness)
	physical_bone.set("joint_constraints/x/angular_spring_damping", config.x_damping)

	physical_bone.set("joint_constraints/y/angular_limit_upper", config.y_upper)
	physical_bone.set("joint_constraints/y/angular_limit_lower", config.y_lower)
	physical_bone.set("joint_constraints/y/angular_spring_stiffness", config.y_stiffness)
	physical_bone.set("joint_constraints/y/angular_spring_damping", config.y_damping)

	physical_bone.set("joint_constraints/z/angular_limit_upper", config.z_upper)
	physical_bone.set("joint_constraints/z/angular_limit_lower", config.z_lower)
	physical_bone.set("joint_constraints/z/angular_spring_stiffness", config.z_stiffness)
	physical_bone.set("joint_constraints/z/angular_spring_damping", config.z_damping)

func _mirror_bone_name(name: String) -> String:
	# PascalCase prefix: LeftXxx -> RightXxx
	if name.begins_with("Left"):
		return "Right" + name.substr(4)
	if name.begins_with("Right"):
		return "Left" + name.substr(5)
	# PascalCase suffix: XxxLeft -> XxxRight
	if name.ends_with("Left"):
		return name.substr(0, name.length() - 4) + "Right"
	if name.ends_with("Right"):
		return name.substr(0, name.length() - 5) + "Left"
	# Lowercase variants with separators
	var short_pairs = [
		[".left", ".right"], ["_left", "_right"], [" left", " right"],
		[".right", ".left"], ["_right", "_left"], [" right", " left"],
		[".l", ".r"], ["_l", "_r"], [" l", " r"],
		[".r", ".l"], ["_r", "_l"], [" r", " l"],
	]
	for p in short_pairs:
		if name.to_lower().ends_with(p[0]):
			return name.substr(0, name.length() - p[0].length()) + p[1]
		if name.to_lower().begins_with(p[0]):
			return p[1] + name.substr(p[0].length())
	return name

#endregion

#region Bone Generator

func _build_scaled_shape(
	skeleton: Skeleton3D,
	bone_id: int,
	physical_bone: PhysicalBone3D,
	ragdoll_bone_config: RagdollBoneConfig
) -> Shape3D:
	var bc_collision_shape := ragdoll_bone_config.collision_shape
	var collider_height := _get_shape_height(bc_collision_shape)
	var new_shape: Shape3D = bc_collision_shape.duplicate(true)

	var leaf_bone_name := ragdoll_bone_config.leaf_bone_name
	if bone_map and leaf_bone_name != "":
		var mapped := bone_map.get_skeleton_bone_name(leaf_bone_name)
		if mapped == StringName():
			push_warning("No leaf bone entry for '%s', skipping." % leaf_bone_name)
		else:
			leaf_bone_name = mapped

	var leaf_bone_id := skeleton.find_bone(leaf_bone_name)
	if leaf_bone_id != -1:
		var local_next := _get_local_next_position(skeleton, bone_id, leaf_bone_id)
		var scalar := local_next.length() / collider_height
		_scale_shape(new_shape, scalar * ragdoll_bone_config.collider_scalar)
		_apply_body_offset(physical_bone, local_next)
	else:
		_apply_body_offset(physical_bone, Vector3.UP * collider_height)

	return new_shape

func _get_shape_height(shape: Shape3D) -> float:
	if shape is CapsuleShape3D:
		return shape.height
	if shape is CylinderShape3D:
		return shape.height
	if shape is BoxShape3D:
		return shape.size.y
	if shape is SphereShape3D:
		return shape.radius * 2.0
	push_warning("_get_shape_height: unrecognized shape type, returning 0")
	return 0.0

func _scale_shape(shape: Shape3D, scalar: float) -> void:
	if not shape:
		return
	if shape is BoxShape3D:
		shape.size *= scalar
	elif shape is SphereShape3D:
		shape.radius *= scalar
	elif shape is CapsuleShape3D or shape is CylinderShape3D:
		shape.radius *= scalar
		shape.height *= scalar

func generate_bone(skeleton: Skeleton3D, simulator: PhysicalBoneSimulator3D, bone_name: String) -> void:
	var skeleton_bone_name := bone_name
	if bone_map:
		var mapped := bone_map.get_skeleton_bone_name(bone_name)
		if mapped == StringName():
			push_warning("No bone map entry for '%s', skipping." %bone_name)
			return
		
		skeleton_bone_name = mapped

	var bone_id := skeleton.find_bone(skeleton_bone_name)
	if bone_id == -1:
		push_warning(skeleton_bone_name + " not found in " + skeleton.name + "! Skipping...")
		return

	var ragdoll_bone_config: RagdollBoneConfig = ragdoll_profile.ragdoll_bone_configs[bone_name]
	var physical_bone := _create_physical_bone(simulator, bone_name, skeleton_bone_name)
	physical_bone.mass = ragdoll_bone_config.mass * total_mass

	var new_shape := _build_scaled_shape(skeleton, bone_id, physical_bone, ragdoll_bone_config)
	_attach_collision(physical_bone, new_shape)

	_apply_joint_config(physical_bone, ragdoll_bone_config.joint_config)
	
func _apply_joint_config(physical_bone: PhysicalBone3D, joint_config: JointConfig) -> void:
	if joint_config is SixDOFJointConfig:
		_set_6dof_joint(physical_bone, joint_config)
	elif joint_config is HingeJointConfig:
		physical_bone.joint_type = PhysicalBone3D.JOINT_TYPE_HINGE
		physical_bone.set("joint_constraints/angular_limit_enabled", true)
		physical_bone.set("joint_constraints/angular_limit_upper", joint_config.angular_limit_upper)
		physical_bone.set("joint_constraints/angular_limit_lower", joint_config.angular_limit_lower)
		physical_bone.joint_rotation = Vector3.UP * PI / 2.0
	elif joint_config is ConeJointConfig:
		_set_cone_joint(physical_bone, joint_config.swing_span, joint_config.twist_span)
	elif joint_config == null:
		pass # NONE — root or detached bone
	else:
		push_warning("_apply_joint_config: unrecognized JointConfig type on %s" % physical_bone.name)

#endregion
