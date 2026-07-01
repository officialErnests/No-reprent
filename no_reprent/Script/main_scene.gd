@tool 
extends Node3D
@export_category("Trash")
@export_tool_button("Revert trash", "Callable") var revert_trash  = revertTrash
@export_tool_button("Clear trash", "Callable") var clear_trash  = clearTrash
@export_category("Slides")
@export_tool_button("Align slides", "Callable") var align_slides  = refreshSlidePositions
@export_tool_button("Rescan all", "Callable") var refresh_action  = _ready
@export var slide_preset: PackedScene = ResourceLoader.load("res://no_reprent/Scenes/preset_slide.tscn")
@export var slides: Array[nb_slide] = []:
	set(p_new_array):
		new_array = p_new_array
		update()

var new_array: Array[nb_slide] = []
var slides_node: Node3D = null
var aligners:Node3D = null
var trash:Node3D = null
func _ready() -> void:
	recheckChild("nb_slides", "slides_node")
	recheckChild("nb_trash", "trash")
	recheckChild("nb_aligner", "aligners")
	scan()

func scan():
	if Engine.is_editor_hint():
		recheckChild("nb_slides", "slides_node")
		recheckChild("nb_trash", "trash")
		slides.clear()
		for child in slides_node.get_children():
			slides.append(child)
		notify_property_list_changed()

func update():
	if Engine.is_editor_hint():
		if !is_inside_tree():
			return
		vailidateChildren()

func vailidateChildren():
	recheckChild("nb_slides", "slides_node")
	recheckChild("nb_trash", "trash")
	var new_slide_amount = new_array.size() - slides_node.get_child_count()
	if new_slide_amount > 0:
		for i in range(new_slide_amount):
			var temp_slide = slide_preset.instantiate()
			var start_num = slides_node.get_child_count() + 1
			for n in range(start_num, start_num + 100):
				if not slides_node.has_node("slide_" + str(n)):
					temp_slide.name = "slide_" + str(n)
					break
			slides_node.add_child(temp_slide)
			temp_slide.slide_manager = self
			temp_slide.owner = get_tree().edited_scene_root
			get_tree().get_edited_scene_root().set_editable_instance(temp_slide, true)
			slides.append(temp_slide)
			# Adds slide to the last position, for comfy ;bb
			var temp_list = slides_node.get_children()
			if temp_list.size() == 0:
				temp_slide.global_transform =  global_transform
			else:
				temp_list.reverse()
				for n in temp_list:
					if n.slide_aligner_counted:
						temp_slide.global_transform =  n.global_transform * temp_slide.slide_aligner_offset
						break

	elif new_slide_amount == 0:
		for i in range(slides.size()):
			slides[i] = new_array[i]
			slides_node.move_child(slides[i], i)
	else:
		var offset:int = 0
		for i in range(slides.size()):
			if i - offset >= new_array.size() or slides[i - offset] != new_array[i -offset]:
				var temp_move = slides.pop_at(i - offset)
				trashSlide(temp_move)
				offset += 1
	notify_property_list_changed()

func revertTrash():
	for child in trash.get_children(): restoreSlide(child)
	notify_property_list_changed()

#after all of these functions call notify_property_list_changed()
func restoreSlide(p_slide):
	var temp_name = p_slide.name
	p_slide.reparent(slides_node)
	p_slide.name = temp_name
	slides.append(p_slide)
	p_slide.slide_deleted = false

#after all of these functions call notify_property_list_changed()
func trashSlide(p_slide):
	var temp_name = p_slide.name
	p_slide.reparent(trash)
	p_slide.name = temp_name
	p_slide.slide_deleted = true

func refreshSlidePositions():
	var is_first = true
	var previous_transform = global_transform
	for i in slides_node.get_children():
		if is_first:
			is_first = false
			i.global_transform = previous_transform
		else:
			i.global_transform = previous_transform * i.slide_aligner_offset
		previous_transform = i.global_transform

func clearTrash():
	recheckChild("nb_trash", "trash")
	for child in trash.get_children(): child.queue_free()

func recheckChild(p_name, p_variable):
	set(p_variable, get_node_or_null(p_name))
	if get(p_variable) == null:
		set(p_variable, Node3D.new())
		get(p_variable).name = p_name
		add_child(get(p_variable))
		match p_name:
			"nb_trash":
				get(p_variable).visible = false
	get(p_variable).owner = get_tree().edited_scene_root

#######################
### Scene functions ###
#######################

func slide_deleteSlide(p_node):
	for i in range(slides.size()):
		if slides[i] == p_node:
			trashSlide(slides.pop_at(i))
	notify_property_list_changed()

func slide_restoreSlide(p_node): 
	restoreSlide(p_node)
	notify_property_list_changed()
