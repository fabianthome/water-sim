extends CanvasLayer

var hidden := true
@onready var label = get_node("Label")

func _process(_delta):
  if Input.is_action_just_pressed("fps"): hidden = !hidden
  if !hidden: label.text = str(int(Engine.get_frames_per_second())) + " FPS"
  elif label.text != "": label.text = ""
