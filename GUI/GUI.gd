extends Control

onready var viewport = $PlanetViewport
onready var viewport_planet = $PlanetViewport/PlanetHolder
onready var viewport_holder = $PlanetHolder
onready var seedtext = $Settings/VBoxContainer/Seed/SeedText
onready var optionbutton = $Settings/VBoxContainer/OptionButton
onready var colorholder = $Settings/VBoxContainer/ColorButtonHolder
onready var picker = $Panel/ColorPicker
onready var colorbutton_scene = preload("res://GUI/ColorPickerButton.tscn")

onready var planets = {
	"Terran Wet": preload("res://Planets/Rivers/Rivers.tscn"),
	"Terran Dry": preload("res://Planets/DryTerran/DryTerran.tscn"),	
	"Islands": preload("res://Planets/LandMasses/LandMasses.tscn"),
	"No atmosphere": preload("res://Planets/NoAtmosphere/NoAtmosphere.tscn"),
	"Gas giant 1": preload("res://Planets/GasPlanet/GasPlanet.tscn"),
	"Gas giant 2": preload("res://Planets/GasPlanetLayers/GasPlanetLayers.tscn"),
	"Ice World": preload("res://Planets/IceWorld/IceWorld.tscn"),
	"Lava World": preload("res://Planets/LavaWorld/LavaWorld.tscn"),
	"Asteroid": preload("res://Planets/Asteroids/Asteroid.tscn"),
	"Black Hole": preload("res://Planets/BlackHole/BlackHole.tscn"),
	"Star": preload("res://Planets/Star/Star.tscn"),
}
const max_pixel_size = 100.0;
var pixels = 100.0
var scale = 1.0
var sd = 0
var colors = []

func _ready():
	for k in planets.keys():
		optionbutton.add_item(k)
	_seed_random()
	_create_new_planet(planets["Terran Wet"])


func _on_OptionButton_item_selected(index):
	var chosen = planets[planets.keys()[index]]
	_create_new_planet(chosen)
	_close_picker()

func _on_SliderPixels_value_changed(value):
	pixels = value
	viewport_planet.get_child(0).set_pixels(value)
	viewport_holder.rect_scale = Vector2(2,2) * max_pixel_size/pixels
	#viewport_holder.rect_position = Vector2(1,1) * max_pixel_size/pixels - Vector2(200,200)
	$Settings/VBoxContainer/Label3.text = "Pixels: " + String(pixels) + "x" + String(pixels)

func _on_SliderScale_value_changed(value):
	scale = value
	viewport_holder.rect_scale = Vector2(1,1)*value

func _on_SliderRotation_value_changed(value):
	viewport_planet.get_child(0).set_rotate(value)

func _on_Control_gui_input(event):
	if (event is InputEventMouseMotion || event is InputEventScreenTouch) && Input.is_action_pressed("mouse"):
		var normal = event.position / Vector2(300, 300)
		viewport_planet.get_child(0).set_light(normal)
		
		if $Panel.visible:
			_close_picker()

func _on_LineEdit_text_changed(new_text):
	call_deferred("_make_from_seed", int(new_text))

func _make_from_seed(new_seed):
	sd = new_seed
	seed(sd)
	viewport_planet.get_child(0).set_seed(sd)

func _create_new_planet(type):
	for c in viewport_planet.get_children():
		c.queue_free()
	
	var new_p = type.instance()
	seed(sd)
	new_p.set_seed(sd)
	new_p.set_pixels(pixels)
	new_p.rect_position = Vector2(0,0)
	viewport_planet.add_child(new_p)
	
	colors = new_p.get_colors()
	_make_color_buttons()

func _make_color_buttons():
	for b in colorholder.get_children():
		b.queue_free()
	
	for i in colors.size():
		var b = colorbutton_scene.instance()
		b.set_color(colors[i])
		b.set_index(i)
		b.connect("color_picked", self, "_on_colorbutton_color_picked")
		b.connect("button_pressed", self, "_on_colorbutton_pressed")
		picker.connect("color_changed", b, "_on_picker_color_changed")
		
		colorholder.add_child(b)

func _on_colorbutton_pressed(button):
	for b in colorholder.get_children():
		b.is_active = false
	button.is_active = true
	$Panel.visible = true
	picker.color = button.own_color

func _on_colorbutton_color_picked(color, index):
	colors[index] = color
	viewport_planet.get_child(0).set_colors(colors)
#	_make_color_buttons()

func _seed_random():
	randomize()
	sd = randi()
	seed(sd)
	seedtext.text = String(sd)
	viewport_planet.get_child(0).set_seed(sd)

func _on_Button_pressed():
	_seed_random()

func _on_ExportPNG_pressed():
#	if OS.get_name() != "HTML5" or !OS.has_feature('JavaScript'):
#		var err = viewport.get_texture().get_data().save_png("res://%s.png"%String(sd))
#	else:
	var planet = viewport_planet.get_child(0)
	var tex = viewport.get_texture().get_data()
	var image = Image.new()
	image.create(pixels * planet.relative_scale, pixels * planet.relative_scale, false, Image.FORMAT_RGBA8)
	var source_xy = 100 - (pixels*(planet.relative_scale-1)*0.5)
	var source_size = 100*planet.relative_scale
	var source_rect = Rect2(source_xy, source_xy,source_size,source_size)
	image.blit_rect(tex, source_rect, Vector2(0,0))
	
	save_image(image)

func export_spritesheet(sheet_size, progressbar):
	var planet = viewport_planet.get_child(0)
	var sheet = Image.new()
	progressbar.max_value = sheet_size.x * sheet_size.y
	
	sheet.create(pixels * sheet_size.x * planet.relative_scale, pixels * sheet_size.y * planet.relative_scale, false, Image.FORMAT_RGBA8)
	planet.override_time = true
	
	var index = 0
	for y in range(sheet_size.y):
		for x in range(sheet_size.x + 1):
			planet.set_custom_time(lerp(0.0, 1.0, (index)/float((sheet_size.x+1) * sheet_size.y)))
			yield(get_tree(), "idle_frame")
			
			if index != 0:
				var image = viewport.get_texture().get_data()
				var source_xy = 100 - (pixels*(planet.relative_scale-1)*0.5)
				var source_size = 100*planet.relative_scale
				var source_rect = Rect2(source_xy, source_xy,source_size,source_size)
				var destination = Vector2(x - 1,y) * pixels * planet.relative_scale
				sheet.blit_rect(image, source_rect, destination)

			index +=1
			progressbar.value = index
	
	
	planet.override_time = false
	save_image(sheet)
	$Popup.visible = false

func save_image(img):
	if OS.get_name() == "HTML5" and OS.has_feature('JavaScript'):
		var filesaver = get_tree().root.get_node("/root/HTML5File")
		filesaver.save_image(img, String(sd))
	else:
		img.save_png("res://%s.png"%String(sd))

func _on_ExportSpriteSheet_pressed():
	$Panel.visible = false
	$Popup.visible = true
	$Popup.set_pixels(pixels * viewport_planet.get_child(0).relative_scale)

func _on_PickerExit_pressed():
	_close_picker()

func _close_picker():
	$Panel.visible = false
	for b in colorholder.get_children():
		b.is_active = false
