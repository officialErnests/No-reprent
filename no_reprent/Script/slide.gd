@tool
class_name nb_slide extends Node3D 

var slide_manager = null
var slide_deleted = false
var initalized = false

@export_category("Slide")
@export_tool_button("Delete", "FileDead") var delete_action = delete
@export_tool_button("Restore", "File") var restore_action = restore
func delete(): 
	if not slide_deleted: 
		slide_manager.slide_deleteSlide(self)
		slide_aligner_obj.queue_free()
func restore(): if slide_deleted: slide_manager.slide_restoreSlide(self)
@export var camera: Camera3D

@export_category("Aligner")
# Used to calculate next slide position
@export var slide_aligner_counted: bool = true
# Used to know if this one needs to be snaped to it
# If false then it creates the floating slide ;bb
@export var slide_aligner_aligned: bool = true

var slide_aligner_packed: PackedScene = ResourceLoader.load("res://no_reprent/Scenes/slide_aligner.tscn")
var slide_aligner_obj = null
@export var slide_aligner_offset: Transform3D = Transform3D(Basis.IDENTITY,Vector3(1.777, 0, 0))
@export var show_aligner: bool = false:
	set(show_aligner_new):
		if not initalized: return
		checkManager()
		show_aligner = show_aligner_new
		if slide_deleted: return
		if show_aligner:
			if slide_manager.aligners.get_child_count() != 0:
				print(1)
				var node_path = slide_manager.aligners.get_child(0).get_meta("slide")
				if has_node(node_path):
					var temp_slide = get_node(node_path)
					print(2)
					if temp_slide != self:
						temp_slide.disableAlign()
						print(3)
				print(4)
				if slide_manager.aligners.get_child_count() != 0:
					print(5)
					for i in slide_manager.aligners.get_children():i.queue_free()
					print(6)
			slide_aligner_obj = slide_aligner_packed.instantiate()
			slide_manager.aligners.add_child(slide_aligner_obj)
			slide_aligner_obj.owner = get_tree().edited_scene_root
			slide_aligner_obj.global_transform = global_transform * slide_aligner_offset.affine_inverse()
			slide_aligner_obj.set_meta("slide", self.get_path())
		else:
			slide_aligner_offset = slide_aligner_obj.global_transform.affine_inverse() *  global_transform
			slide_aligner_obj.queue_free()

func disableAlign():
	if slide_aligner_obj == null: return
	slide_aligner_offset = slide_aligner_obj.global_transform.affine_inverse() *  global_transform
	slide_aligner_obj.queue_free()
	show_aligner = false
	notify_property_list_changed()

func _ready() -> void:
	state_machine = animation_tree.tree_root
	initalized = true
	animation_enabled = true

	var x = 1
	while state_machine.has_node("VAR_" + str(x)): x+=1
	animation_variation = x - 1

	checkManager()
	if not Engine.is_editor_hint():
		animation_tree.animation_finished.connect(animationFinished)

func checkManager():
	if not slide_manager:
		if not get_parent():
			return
		var temp_one = get_parent().get_parent()
		if temp_one is nb_slide_manager:
			temp_one.scan()

@export_category("Animation")
@export var animation_tree: AnimationTree
var state_machine: AnimationNodeStateMachine
@export_tool_button("RESET ANIMATION TREE", "Reload") var reset_animation = animationTreeReset
@export var animation_enabled: bool:
	set(new_animation_enabled):
		if not initalized: return
		animation_enabled = new_animation_enabled
		animation_tree.active = animation_enabled
@export var animation_variation: int:
	set(new_animation_variation):
		if not initalized: return
		animation_variation = max(new_animation_variation, 0)
		updateBranches()
		animationUpdateVariation()
@export_tool_button("Play intro", "PlayStart") var play_intro = introAnimation
@export var variation: int:
	set(new_variation):
		if not initalized: return
		variation = clamp(new_variation, 0, animation_variation)
		playAnimationVariation(variation)
@export_tool_button("Play exit animation", "PlayStart") var play_exit = exitAnimation

func animationTreeReset():
	animation_tree.set_meta("variation", 0)
	animation_tree.set_meta("is_playing", false)
	for i in state_machine.get_node_list():
		state_machine.remove_node(i)

	var t_init_nodes = {
		"ENTRY1": Vector2(-100,0), 
		"ENTRY": Vector2(0,100), 
		"RESET": Vector2(100,0), 
		"EXIT": Vector2(200,100)
	}
	animationAddNodes(t_init_nodes)
	var t_init_transitions = [
		{
			"from": "Start",
			"to": "ENTRY1",
			"x_fade": 0,
			"expression": "",
			"switch_mode": AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
		},
		{
			"from": "ENTRY1",
			"to": "RESET",
			"x_fade": 0,
			"expression": "",
			"switch_mode": AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
		},
		{
			"from": "ENTRY",
			"to": "EXIT",
			"x_fade": 0.2,
			"expression": "!get_meta('is_playing')",
			"switch_mode": AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
		},
		{
			"from": "EXIT",
			"to": "RESET",
			"x_fade": 0,
			"expression": "get_meta('is_playing')",
			"switch_mode": AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
		},
		{
			"from": "RESET",
			"to": "ENTRY",
			"x_fade": 0,
			"expression": "get_meta('is_playing')",
			"switch_mode": AnimationNodeStateMachineTransition.SWITCH_MODE_AT_END
		}
	]
	animationAddTransitions(t_init_transitions)
	animationUpdateVariation()
func animationUpdateVariation():
	var curent_size = animation_variation - (animation_tree.tree_root.get_node_list().size() - 6)
	if curent_size > 0:
		var t_init_nodes = {}
		var t_init_transitions = []
		for i in range(curent_size):
			var t_spot = animation_variation - curent_size + i + 1
			var t_this_name = "VAR_" + str(t_spot)
			var t_prev_name = "VAR_" + str(t_spot - 1)
			t_init_nodes[t_this_name] = Vector2(100,100 + t_spot * 100)
			var t_transition = {}
			if t_spot == 1:
				t_transition = {
					"from": "ENTRY",
					"to": t_this_name,
					"x_fade": 0.2,
					"expression": "get_meta('variation') > 0",
					"switch_mode": AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
				}
				t_init_transitions.append(t_transition)
				t_transition = {
					"from": t_this_name,
					"to": "ENTRY",
					"x_fade": 0.2,
					"expression": "get_meta('variation') <= 0",
					"switch_mode": AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
				}
				t_init_transitions.append(t_transition)
			else:
				t_transition = {
					"from": t_prev_name,
					"to": t_this_name,
					"x_fade": 0.2,
					"expression": "get_meta('variation') > " + str(t_spot - 1),
					"switch_mode": AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
				}
				t_init_transitions.append(t_transition)
				t_transition = {
					"from": t_this_name,
					"to": t_prev_name,
					"x_fade": 0.2,
					"expression": "get_meta('variation') <= " + str(t_spot - 1),
					"switch_mode": AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
				}
				t_init_transitions.append(t_transition)
			t_transition = {
				"from": t_this_name,
				"to": "EXIT",
				"x_fade": 0.2,
				"expression": "!get_meta('is_playing')",
				"switch_mode": AnimationNodeStateMachineTransition.SWITCH_MODE_IMMEDIATE
			}
			t_init_transitions.append(t_transition)
		animationAddNodes(t_init_nodes)
		animationAddTransitions(t_init_transitions)
	elif curent_size < 0:
		for i in range(abs(curent_size)):
			var t_spot = animation_variation - curent_size - i
			print(t_spot, "VAR_"+str(t_spot))
			state_machine.remove_node("VAR_"+str(t_spot))
func animationAddNodes(p_nodes):
	for i in p_nodes:
		var t_Animation_node := AnimationNodeAnimation.new()
		if i == "ENTRY1":
			t_Animation_node.animation = "ENTRY"
		else:
			t_Animation_node.animation = i
		if state_machine.has_node(i): continue
		state_machine.add_node(i, t_Animation_node, p_nodes[i])
func animationAddTransitions(p_transitions):
	for i in p_transitions:
		if state_machine.has_transition(i.from, i.to): continue
		var t_transition := AnimationNodeStateMachineTransition.new()
		t_transition.xfade_time = i.x_fade
		t_transition.advance_expression = i.expression
		t_transition.switch_mode = i.switch_mode
		t_transition.advance_mode = AnimationNodeStateMachineTransition.ADVANCE_MODE_AUTO
		state_machine.add_transition(i.from, i.to, t_transition)

func introAnimation():
	print("Intro anim")
	animation_tree.set_meta("variation", 0)
	animation_tree.set_meta("is_playing", true)
	variation = 0
func playAnimationVariation(p_variation):
	print("Variation anim: " + str(p_variation))
	animation_tree.set_meta("variation", p_variation)
func exitAnimation():
	print("Exit anim")
	if variation != 0 && get_meta("update_branch")[variation - 1] != -1:
			slide_manager.next_slide = get_meta("update_branch")[variation - 1]
	animation_tree.set_meta("is_playing", false)

func animationFinished(anim_name: StringName) -> void:
	if anim_name == "EXIT" && slide_manager:
		slide_manager.nextSlide()

@export_category("Branching paths")
@export var branching: Array[int] = []:
	set(new_branch):
		if new_branch.size() == branching.size():
			branching = new_branch
			set_meta("update_branch", branching)

func updateBranches():
	var diffrance = animation_variation - branching.size()
	if diffrance > 0:
		for i in diffrance: branching.append(-1)
	else:
		branching.resize(animation_variation)
	notify_property_list_changed()
