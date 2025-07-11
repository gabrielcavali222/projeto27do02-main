
extends CharacterBody2D


enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck,
	dead
	
}
const MAGICAL_ORB = preload("res://entities/magical_orb.tscn")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var reload_timer: Timer = $ReloadTimer


@export var max_speed = 85
@export var acceleration = 100
@export var deceleration = 100
const JUMP_VELOCITY = -300.0

var jump_count = 0
@export var max_jump_count = 2
var direction = 0
var player_direction = 1
var status: PlayerState

func move(delta):
	update_direction()
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	

func _ready() -> void:
	go_to_idle_state()
	anim.frame_changed.connect(_on_animation_frame_changed)
func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta


	if Input.is_action_just_pressed("shot"):
		
		anim.play("shot")



	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.dead:
			dead_state(delta)

	move_and_slide()

func _on_animation_frame_changed():
	if anim.animation == "shot" and anim.frame == 2:
		var new_orb = MAGICAL_ORB.instantiate()
		add_sibling(new_orb)
		new_orb.position = $OrbStartPosition.global_position
		new_orb.set_direction(player_direction)

func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")
	
func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")

func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1

func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")
	


func go_to_duck_state():
	status = PlayerState.duck
	anim.play("duck")
	collision_shape.shape.radius = 4
	collision_shape.shape.height = 13
	collision_shape.position.y = 6
	
	hitbox_collision_shape.shape.size.y = 10
	hitbox_collision_shape.position.y = 8


func exit_from_duck_state():
	collision_shape.shape.radius = 9
	collision_shape.shape.height = 26
	collision_shape.position.y = 0

	hitbox_collision_shape.shape.size.y = 25
	hitbox_collision_shape.position.y = 0.5
	
func go_to_dead_state():
	if status == PlayerState.dead:
		return
	
	status = PlayerState.dead
	anim.play("dead")
	velocity.x = 0
	reload_timer.start()
	
func idle_state(delta):
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return

	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

	if Input.is_action_pressed("duck"):
		go_to_duck_state()
		return

func walk_state(delta):
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		
	if !is_on_floor():
		jump_count += 1
		go_to_fall_state()
		return

func dead_state(_delta):
	pass

func jump_state(delta):
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		
	if velocity.y > 0:
		go_to_fall_state()
		return
	
func fall_state(delta):
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
	
	if is_on_floor():
		jump_count = 0
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return


func duck_state(_delta):
	update_direction()
	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return


func update_direction():
	direction = Input.get_axis("left", "right")
	
	if direction < 0:
		anim.flip_h = true
		player_direction = -1
	elif direction > 0:
		anim.flip_h = false
		player_direction = 1

	if has_node("OrbStartPosition"):
		var orb_start = $OrbStartPosition
		orb_start.position.x = abs(orb_start.position.x) * player_direction
		
		
func can_jump() -> bool:
	return jump_count < max_jump_count


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		hit_lethal_area()
		
func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		go_to_dead_state()


func hit_enemy(area: Area2D):
	if velocity.y > 0:
		# inimigo morre
		area.get_parent().take_damage()
		go_to_jump_state()
	else:
		# player morre
		go_to_dead_state()
	
	
func hit_lethal_area():
	go_to_dead_state()


func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()


func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "shot":
		go_to_idle_state()
		return
	
