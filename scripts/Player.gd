extends CharacterBody2D

# 移动参数
@export var base_speed: float = 300.0
@export var acceleration: float = 1500.0
@export var friction: float = 800.0
@export var ice_friction: float = 200.0  # 冰面摩擦力更小
@export var jump_force: float = -400.0
@export var gravity: float = 980.0

# 动作状态
var is_jumping: bool = false
var is_spinning: bool = false
var is_gliding: bool = false
var is_backsliding: bool = false
var spin_timer: float = 0.0
var glide_timer: float = 0.0
var backslide_timer: float = 0.0

# 速度和方向
var current_speed: float = 0.0
var facing_direction: int = 1  # 1 = 右, -1 = 左

# 游戏管理器引用
var game_manager: Node2D

func _ready():
	game_manager = get_node("/root/Main")
	
	# 设置碰撞形状
	var shape = $CollisionShape2D
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 60)
	shape.shape = rect
	
	# 设置精灵（临时用颜色方块代替）
	var sprite = $Sprite2D
	var texture = ImageTexture.new()
	var image = Image.create(40, 60, false, Image.FORMAT_RGB8)
	image.fill(Color(0.8, 0.3, 0.3))
	sprite.texture = ImageTexture.create_from_image(image)

func _physics_process(delta):
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
		is_jumping = true
	else:
		if is_jumping:
			is_jumping = false
			# 着陆时可以获得分数
			if abs(velocity.x) > 400:
				game_manager.perform_action("jump")
	
	# 处理输入
	handle_input(delta)
	
	# 更新动作计时器
	update_action_timers(delta)
	
	# 更新速度
	current_speed = abs(velocity.x)
	
	# 移动
	move_and_slide()

func handle_input(delta):
	var input_dir = Input.get_axis("move_left", "move_right")
	
	# 处理后滑状态
	if is_backsliding:
		# 后滑时反向控制
		input_dir *= -1
		velocity.x = move_toward(velocity.x, input_dir * base_speed * 1.5, acceleration * delta)
	else:
		# 正常移动
		if input_dir != 0:
			velocity.x = move_toward(velocity.x, input_dir * base_speed, acceleration * delta)
			facing_direction = sign(input_dir)
		else:
			# 应用摩擦力（冰面摩擦力较小）
			var current_friction = ice_friction if is_gliding else friction
			velocity.x = move_toward(velocity.x, 0, current_friction * delta)
	
	# 跳跃
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		is_jumping = true
	
	# 旋转
	if Input.is_action_just_pressed("spin") and not is_spinning:
		perform_spin()
	
	# 滑行
	if Input.is_action_pressed("glide") and is_on_floor():
		if not is_gliding:
			is_gliding = true
			glide_timer = 0.0
			game_manager.perform_action("glide")
	else:
		is_gliding = false
	
	# 后滑
	if Input.is_action_just_pressed("backslide") and is_on_floor():
		if not is_backsliding:
			is_backsliding = true
			backslide_timer = 0.0
			game_manager.perform_action("backslide")
			# 后滑时增加速度
			velocity.x *= 1.2

func perform_spin():
	is_spinning = true
	spin_timer = 0.5  # 旋转持续时间
	game_manager.perform_action("spin")
	
	# 旋转时的视觉效果
	var tween = create_tween()
	tween.tween_property($Sprite2D, "rotation", $Sprite2D.rotation + TAU, 0.5)
	tween.tween_callback(func(): $Sprite2D.rotation = 0)

func update_action_timers(delta):
	# 更新旋转计时器
	if is_spinning:
		spin_timer -= delta
		if spin_timer <= 0:
			is_spinning = false
	
	# 更新滑行计时器
	if is_gliding:
		glide_timer += delta
		# 每秒获得额外分数
		if int(glide_timer) > int(glide_timer - delta):
			game_manager.add_score("持续滑行", 50)
	
	# 更新后滑计时器
	if is_backsliding:
		backslide_timer += delta
		if backslide_timer > 2.0:  # 后滑最多持续2秒
			is_backsliding = false

func get_speed() -> float:
	return current_speed

func get_action_state() -> String:
	if is_spinning:
		return "旋转"
	elif is_gliding:
		return "滑行"
	elif is_backsliding:
		return "后滑"
	elif is_jumping:
		return "跳跃"
	else:
		return "正常" 