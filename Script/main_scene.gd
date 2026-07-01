@tool 
extends Node3D

@export_tool_button("Refresh", "Callable") var refresh_action  = _ready
@export_tool_button("Revert trash", "Callable") var revert_trash  = revertTrash
@export_tool_button("Clear trash", "Callable") var clear_trash  = clearTrash
@export var slides: Array[nb_slide] = []:
	set(p_new_array):
		new_array = p_new_array
		update()

var new_array: Array[nb_slide] = []
var slides_node: Node3D = null
var trash:Node3D = null

func _ready() -> void:
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
			var temp_slide = nb_slide.new()
			var start_num = slides_node.get_child_count() + 1
			for n in range(start_num, start_num + 100):
				if not slides_node.has_node("slide_" + str(n)):
					temp_slide.name = "slide_" + str(n)
					break
			slides_node.add_child(temp_slide)
			temp_slide.owner = get_tree().edited_scene_root
			slides.append(temp_slide)
	elif new_slide_amount == 0:
		for i in range(slides.size()):
			slides[i] = new_array[i]
			slides_node.move_child(slides[i], i)
	else:
		var offset:int = 0
		for i in range(slides.size()):
			if i - offset >= new_array.size():
				var temp_move = slides.pop_at(i - offset)
				var temp_name = temp_move.name
				temp_move.reparent(trash)
				temp_move.name = temp_name
				offset += 1
			elif slides[i - offset] != new_array[i -offset]:
				var temp_move = slides.pop_at(i - offset)
				var temp_name = temp_move.name
				temp_move.reparent(trash)
				temp_move.name = temp_name
				offset += 1

func revertTrash():
	recheckChild("nb_trash", "trash")
	recheckChild("nb_slides", "slides_node")
	for child in trash.get_children():
		var temp_name = child.name
		child.reparent(slides_node)
		child.name = temp_name
		slides.append(child)
	notify_property_list_changed()



func clearTrash():
	recheckChild("nb_trash", "trash")
	for child in trash.get_children(): child.queue_free()

func recheckChild(p_name, p_variable):
	set(p_variable, get_node_or_null(p_name))
	if get(p_variable) == null:
		set(p_variable, Node3D.new())
		get(p_variable).name = p_name
		add_child(get(p_variable))
	get(p_variable).owner = get_tree().edited_scene_root