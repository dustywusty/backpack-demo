extends Node2D


# Declare member variables here. Examples:
var bag_map

# Called when the node enters the scene tree for the first time.
func _ready():
	bag_map = create_map()
	
	# yuck lol. no filter yet? sheesh
	var enabled_slots = []
	for row in bag_map:
		for slot in row:
			if slot.enabled:
				enabled_slots.append(slot)

	for slot in enabled_slots:
		var sprite = Sprite.new()
		sprite.name = "Row " + str(slot.position.y + 1) + ", Slot " + str(slot.position.x + 1)
		sprite.scale = Vector2(float(64) / 450, float(64) / 450) # zonk.png is 450x450px, but we want something that is 64x64px
		sprite.position = Vector2(64 * slot.position.x, 64 * slot.position.y)
		sprite.centered = false
		sprite.texture = load("res://assets/zonk.png")
		sprite.modulate = Color(1, 1, 1)
		add_child(sprite)
		slot.sprite = sprite


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


# default map is 7x7, with the center 3x3 enabled to start
func create_map(size = 7, size_of_enabled = 3):
	var map = []
	var enabled_starting_index = floor((size - size_of_enabled) / 2)
	var enabled_ending_index = enabled_starting_index + size_of_enabled - 1
	
	for y in size:
		var row = []
		for x in size:
			if (
					enabled_starting_index <= x and 
					x <= enabled_ending_index and 
					enabled_starting_index <= y and 
					y <= enabled_ending_index
			):
				row.append({
					"enabled": true,
					"contains": null,
					"sprite": null,
					"position": Vector2(x, y),
				})
			else:
				row.append({
					"enabled": false,
					"contains": null,
					"sprite": null,
					"position": null
				})
		map.append(row)
		
	return map


func _on_Button_pressed():
	
	# yuck lol. no filter yet? sheesh
	var enabled_slots = []
	for row in bag_map:
		for slot in row:
			if slot.enabled:
				enabled_slots.append(slot)
				
	# unplace everything 
		# (for now, maybe just wipe all `contains` and set all sprite.modulate to Color(1,1,1))
	for slot in enabled_slots:
		slot.contains = null
		slot.sprite.modulate = Color(1,1,1)
		
	
	# create 3 items (1x1 green, 2x1 blue, 2x2 yellow)
	var green1x1 = {
		"color": Color(0.3, 0.8, 0.3),
		"shape": [
			Vector2(0,0)
		],
		"position": null,
		"absolutePositions": null,
	}
	
	var blue2x1 = {
		"color": Color(0.3, 0.3, 0.8),
		"shape": [
			Vector2(0, 0),
			Vector2(0, 1),
		],
	}
	
	var items = [blue2x1, green1x1]
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# for each item, starting with the largest, pick a random location and see if it fits.
	
	for item in items:
		var random_enabled_slot = enabled_slots[rng.randi_range(0, enabled_slots.size() - 1)]
		# if it does, place it.
		var place_succeeded = place_item(item, random_enabled_slot, enabled_slots)
		
		# NEXT EFFORT: if it does not, see if it fits when rotated.
		# if it still does not, loop through the enabled slots of the inventory and see if it fits anywhere.
		if not place_succeeded:
			for slot in enabled_slots:
				place_succeeded = place_item(item, slot, enabled_slots)
				if place_succeeded:
					break
		
		# if it still does not, do not place it.


# attempts to place an item. if it succeeds, it returns true, otherwise it returns false
func place_item(item, slot, slots):
	if not slot.enabled:
		return false
		
	var slots_to_fill = []
		
	for position in item.shape:
		var position_in_bag = position + slot.position
		var slot_to_check = find_slot(position_in_bag, slots)
		
		# sometimes an item extends off the grid...
		if not slot_to_check:
			print("couldn't find slot " + str(position_in_bag))
			return false
			
		if slot_to_check.contains != null:
			return false
			
		slots_to_fill.append(slot_to_check)
		
	# we didn't fail any of the slots in the item, so let's place it
	for slot in slots_to_fill:
		slot.contains = item
		slot.sprite.modulate = item.color
	return true


# grabs the bag slot with the given position
func find_slot(position: Vector2, slots):
	for slot in slots:
		if slot.position.x == position.x and slot.position.y == position.y:
			return slot
	
	return null
