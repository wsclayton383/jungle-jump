extends CharacterBody2D

signal life_changed
signal died

enum {
	IDLE,
	RUN,
	JUMP,
	HURT,
	DEAD,
}

@export var gravity = 750
@export var run_speed = 150
@export var jump_speed = -300

var life = 5:
	set = set_life

var state = IDLE


func _ready():
	change_state(IDLE)


func _physics_process(delta):
	velocity.y += gravity * delta
	get_input()
	move_and_slide()
	if state == HURT:
		return
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("danger"):
			hurt()
		if collision.get_collider().is_in_group("enemies"):
			if position.y < collision.get_collider().position.y:
				collision.get_collider().take_damage()
				velocity.y = -200
			else:
				hurt()
	if state == JUMP and is_on_floor():
		change_state(IDLE)
	if state == JUMP and velocity.y > 0:
		$AnimationPlayer.play("jump_down")


func set_life(value):
	life = value
	life_changed.emit(life)
	if life <= 0:
		change_state(DEAD)


func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			$AnimationPlayer.play("idle")
		RUN:
			$AnimationPlayer.play("run")
		JUMP:
			$AnimationPlayer.play("jump_up")
		HURT:
			$AnimationPlayer.play("hurt")
			velocity.y = -200
			velocity.x = -100 * sign(velocity.x)
			$HurtTimer.start()
			life -= 1
			await $HurtTimer.timeout
			change_state(IDLE)
		DEAD:
			velocity = Vector2.ZERO
			await $HurtTimer.timeout
			died.emit()
			hide()


func get_input():
	if state == HURT:
		return
	var right = Input.is_action_pressed("right")
	var left = Input.is_action_pressed("left")
	var jump = Input.is_action_just_pressed("jump")
	# movement occurs in all states
	velocity.x = 0
	if right:
		velocity.x += run_speed
		$Sprite2D.flip_h = false
	if left:
		velocity.x -= run_speed
		$Sprite2D.flip_h = true
	# only allow jumping when on the ground
	if jump and is_on_floor():
		change_state(JUMP)
		velocity.y = jump_speed
	# IDLE transitions to RUN when moving
	if state == IDLE and velocity.x != 0:
		change_state(RUN)
	# RUN transitions to IDLE when standing still
	if state == RUN and velocity.x == 0:
		change_state(IDLE)
	# transition to JUMP when in the air
	if state in [IDLE, RUN] and !is_on_floor():
		change_state(JUMP)


func reset(_position):
	position = _position
	show()
	change_state(IDLE)
	life = 5


func hurt():
	if state != HURT:
		change_state(HURT)


func _on_hurt_timer_timeout():
	change_state(IDLE)
