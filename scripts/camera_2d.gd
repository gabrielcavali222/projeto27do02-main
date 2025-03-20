extends Camera2D


var player: Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")


func _physics_process(delta: float) -> void:
	self.position = player.position
