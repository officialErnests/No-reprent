@tool
class_name nb_slide extends Node3D 

var slide_manager = null
var slide_deleted = false
var initalized = false

@export_category("Slide")
@export_tool_button("Delete", "Callable") var delete_action = delete
@export_tool_button("Restore", "Callable") var restore_action = restore
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
    initalized = true
    checkManager()

func checkManager():
    if not slide_manager:
        var temp_one = get_parent().get_parent()
        if temp_one is nb_slide_manager:
            temp_one.scan()