@tool
class_name SixDOFJointConfig
extends JointConfig

@export_subgroup("X Axis")
@export var x_upper: float = 0.0
@export var x_lower: float = 0.0
@export var x_stiffness: float = 0.0
@export var x_damping: float = 0.0

@export_subgroup("Y Axis")
@export var y_upper: float = 0.0
@export var y_lower: float = 0.0
@export var y_stiffness: float = 0.0
@export var y_damping: float = 0.0

@export_subgroup("Z Axis")
@export var z_upper: float = 0.0
@export var z_lower: float = 0.0
@export var z_stiffness: float = 0.0
@export var z_damping: float = 0.0
