@tool
class_name nb_slide extends Node3D 

var slide_manager = null
var slide_deleted = false

@export_category("Slide")
@export_tool_button("Delete", "Callable") var delete_action = delete
@export_tool_button("Restore", "Callable") var restore_action = restore
func delete(): 
    if not slide_deleted: 
        slide_manager.slide_deleteSlide(self)
        slide_aligner_obj.queue_free()
func restore(): if slide_deleted: slide_manager.slide_restoreSlide(self)


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
        show_aligner = show_aligner_new
        if slide_deleted: return
        if show_aligner:
            if slide_manager.aligners.get_child_count() == 0:
                slide_aligner_obj = slide_aligner_packed.instantiate()
                slide_manager.aligners.add_child(slide_aligner_obj)
                slide_aligner_obj.owner = get_tree().edited_scene_root
                slide_aligner_obj.global_transform = global_transform * slide_aligner_offset.inverse()
            else:
                #TODO delete the other one
                pass
        else:
            slide_aligner_offset = slide_aligner_obj.global_transform.inverse() *  global_transform
            slide_aligner_obj.queue_free()
