extends Node2D


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/grassland.tscn")

func _on_sair_pressed():
	get_tree().quit()
