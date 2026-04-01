@tool
extends Resource
class_name RagdollProfile

##The dictionary of bone name keys and RagdollBoneConfig values that will be used to map colliders and joints to bones.
@export var ragdoll_bone_configs : Dictionary[StringName, RagdollBoneConfig] = {}
