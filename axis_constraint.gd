@tool
class_name AxisConstraint
extends RefCounted
var upper: float
var lower: float
var stiffness: float
var damping: float

func _init(p_upper: float, p_lower: float, p_stiffness: float, p_damping: float) -> void:
	upper = p_upper
	lower = p_lower
	stiffness = p_stiffness
	damping = p_damping

static func from_vec4(v: Vector4) -> AxisConstraint:
	return AxisConstraint.new(v.x, v.y, v.z, v.w)
