extends Node2D

# 分数系统变量
var current_score: int = 0
var total_score: int = 0
var combo_count: int = 0
var combo_multiplier: float = 1.0
var combo_timer: float = 0.0
var last_action: String = ""

# 参数配置
var parameters = {
	"combo_window": 5.0,  # 连击窗口时间
	"base_score": 100,    # 基础分数
	"speed_multiplier": 1.5,  # 速度倍率
	"jump_score": 200,    # 跳跃分数
	"spin_score": 300,    # 旋转分数
	"glide_score": 150,   # 滑行分数
	"backslide_score": 250,  # 后滑分数
	"collect_score": 500,  # 收集物分数
	"combo_threshold": 3,  # 连击触发阈值
	"max_combo_multiplier": 5.0  # 最大连击倍率
}

# UI引用
@onready var score_label = $UI/ScoreDisplay/ScoreLabel
@onready var combo_label = $UI/ScoreDisplay/ComboLabel
@onready var speed_label = $UI/ScoreDisplay/SpeedLabel
@onready var action_label = $UI/ScoreDisplay/ActionLabel
@onready var parameter_container = $UI/ParameterPanel/Parameters

# 玩家引用
var player: Node2D

func _ready():
	player = $World/Player
	setup_parameter_controls()
	setup_collectibles()

func _process(delta):
	# 更新连击计时器
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			settle_score()

func add_score(action: String, base_points: int):
	# 计算最终分数
	var speed_bonus = 1.0
	if player and player.has_method("get_speed"):
		var speed = player.get_speed()
		speed_bonus = 1.0 + (speed / 500.0) * parameters.speed_multiplier
	
	var final_score = int(base_points * combo_multiplier * speed_bonus)
	current_score += final_score
	
	# 更新连击
	if action == last_action:
		combo_count += 1
	else:
		combo_count = 1
	last_action = action
	
	# 更新连击倍率
	if combo_count >= parameters.combo_threshold:
		combo_multiplier = min(combo_multiplier + 0.5, parameters.max_combo_multiplier)
	
	# 重置连击计时器
	combo_timer = parameters.combo_window
	
	# 更新UI
	update_ui(action)
	
	# 显示分数弹出
	show_score_popup(final_score, combo_multiplier > 1.0)

func settle_score():
	# 结算当前分数
	total_score += current_score
	current_score = 0
	combo_count = 0
	combo_multiplier = 1.0
	last_action = ""
	combo_timer = 0.0
	
	update_ui("结算")

func update_ui(action: String = ""):
	if score_label:
		score_label.text = "分数: %d (+%d)" % [total_score, current_score]
	if combo_label:
		combo_label.text = "连击: x%.1f (%d)" % [combo_multiplier, combo_count]
	if action_label:
		action_label.text = "动作: " + action
	if speed_label and player and player.has_method("get_speed"):
		speed_label.text = "速度: %.0f" % player.get_speed()

func show_score_popup(score: int, is_combo: bool):
	# 创建分数弹出文本
	var popup = Label.new()
	popup.text = "+%d" % score
	if is_combo:
		popup.text += " COMBO!"
		popup.modulate = Color(1, 0.8, 0)
	else:
		popup.modulate = Color(1, 1, 1)
	
	popup.add_theme_font_size_override("font_size", 24)
	
	if player:
		popup.position = player.global_position + Vector2(0, -50)
		add_child(popup)
		
		# 创建动画
		var tween = create_tween()
		tween.parallel().tween_property(popup, "position:y", popup.position.y - 50, 0.5)
		tween.parallel().tween_property(popup, "modulate:a", 0, 0.5)
		tween.tween_callback(popup.queue_free)

func setup_parameter_controls():
	# 为每个参数创建滑块控件
	for param_name in parameters:
		var container = HBoxContainer.new()
		parameter_container.add_child(container)
		
		var label = Label.new()
		label.text = param_name.replace("_", " ").capitalize()
		label.custom_minimum_size.x = 120
		container.add_child(label)
		
		var slider = HSlider.new()
		slider.custom_minimum_size.x = 100
		slider.value = parameters[param_name]
		
		# 设置滑块范围
		match param_name:
			"combo_window":
				slider.min_value = 1.0
				slider.max_value = 10.0
				slider.step = 0.5
			"base_score", "jump_score", "spin_score", "glide_score", "backslide_score", "collect_score":
				slider.min_value = 50
				slider.max_value = 1000
				slider.step = 50
			"speed_multiplier":
				slider.min_value = 0.5
				slider.max_value = 3.0
				slider.step = 0.1
			"combo_threshold":
				slider.min_value = 1
				slider.max_value = 10
				slider.step = 1
			"max_combo_multiplier":
				slider.min_value = 2.0
				slider.max_value = 10.0
				slider.step = 0.5
		
		container.add_child(slider)
		
		var value_label = Label.new()
		value_label.text = str(parameters[param_name])
		value_label.custom_minimum_size.x = 40
		container.add_child(value_label)
		
		# 连接信号
		slider.value_changed.connect(func(value): 
			parameters[param_name] = value
			value_label.text = "%.1f" % value if value is float else str(int(value))
		)

func setup_collectibles():
	# 在场景中生成一些收集物
	var collectibles_parent = $World/Collectibles
	for i in range(5):
		var collectible = create_collectible()
		collectible.position = Vector2(200 + i * 200, 500 + randf_range(-100, 100))
		collectibles_parent.add_child(collectible)

func create_collectible():
	var area = Area2D.new()
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20
	shape.shape = circle
	area.add_child(shape)
	
	var sprite = ColorRect.new()
	sprite.size = Vector2(40, 40)
	sprite.position = Vector2(-20, -20)
	sprite.color = Color(1, 1, 0)
	area.add_child(sprite)
	
	area.body_entered.connect(func(body):
		if body == player:
			add_score("收集", parameters.collect_score)
			area.queue_free()
	)
	
	return area

# 被玩家调用的动作函数
func perform_action(action_name: String):
	match action_name:
		"jump":
			add_score("跳跃", parameters.jump_score)
		"spin":
			add_score("旋转", parameters.spin_score)
		"glide":
			add_score("滑行", parameters.glide_score)
		"backslide":
			add_score("后滑", parameters.backslide_score) 