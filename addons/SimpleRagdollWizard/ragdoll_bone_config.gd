@tool
extends Resource
class_name RagdollBoneConfig

##The relative mass of the PhysicalBone3D. This is multiplied by the Ragdoll's total mass.
@export var mass : float
##A bone in the armature that represents the "next" bone in the ragdoll. This is used to scale the collider apropriately and offset the PhysicalBone3D.
@export var leaf_bone_name : StringName
##The collision shape to be used. Note that if a leaf bone is assigned, this will be scaled to reach the next point in the armature. The size of the shape will therefore only be the relative proportions of the collider, not its actual size.
@export var collision_shape : Shape3D
##If a leaf bone is used, the collider size will be multiplied by this value. If there is no leaf bone, this value is ignored and the size of the collider shape is used instead.
@export var collider_scalar: float = 0.85

##This will be used to help automatically configure the joint appropriately. Leaving this empty will result in no joint, which means the ragdoll part will not be attached to anything.
@export var joint_config: JointConfig
