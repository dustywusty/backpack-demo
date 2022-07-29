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
		# (for now, just wipe all `contains` and set all sprite.modulate to Color(1,1,1))
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
	
	var t_tetrimino = {
		"color": Color(0.7, 0.7, 0.3),
		"shape": [
			Vector2(0, 0),
			Vector2(1, 0),
			Vector2(2, 0),
			Vector2(1, 1),
		]
	}
	
	
	var items = [t_tetrimino, blue2x1, green1x1]
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	t_tetrimino = randomize_rotation(t_tetrimino, rng)
	blue2x1 = randomize_rotation(blue2x1, rng)
	green1x1 = randomize_rotation(green1x1, rng)
	
	
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

# rotates the item 90deg. I'm not doing anything with the clockwise flag for now
func rotate_item(item, clockwise = true):
	var minX = INF
	var minY = INF
	var maxX = 0
	var maxY = 0
	
	# get outermost bounds
	for slot in item.shape:
		if slot.x > maxX:
			maxX = slot.x
		if slot.y > maxY:
			maxY = slot.y
			
		if slot.x < minX:
			minX = slot.x
		if slot.y < minY:
			minY = slot.y
			
	item.shape = rotate_shape(item.shape, minX, minY, maxX, maxY, clockwise)
	
	item.shape = normalize_shape(item.shape)
	
	return item
		
# recursive fn. rotates the outermost shell, then calls itself on the remainder
func rotate_shape(shape, minX, minY, maxX, maxY, clockwise = true):
	# transpose each slot in the current ring, starting with the outermost, and group the rest
	print("%%%%%%%%%%%%%%%%%%")
	print(shape)
	print("----")
	
	while minX < maxX or minY < maxY:
		for index in shape.size():
			var slot = shape[index]
			# if we're outside the current ring, skip
			if slot.x > maxX or slot.x < minX or slot.y > maxY or slot.y < minY:
				continue
			# if we're the top row, rotate to the right column, top to bottom
			if slot.y == minY:
				shape[index].x = maxX - (maxX - maxY)
				shape[index].y = slot.x
			# if we're the right column, rotate to the bottom row, right to left
			elif slot.x == maxX:
				shape[index].x = maxY - slot.y
				shape[index].y = maxY - (maxY - maxX)
			# if we're the bottom row, rotate to the left column, bottom to top
			elif slot.y == maxY:
				shape[index].x = minX - (minX - minY)
				shape[index].y = slot.x
			# if we're the left column, rotate to the top row, left to right
			elif slot.x == minX:
				shape[index].x = maxY - slot.y
				shape[index].y = minY - (minY - minX)
				
			# otherwise, do nothing
			var after_slot = shape[index]
			print(slot, "->", after_slot)
				
		minX += 1
		if minX < maxX:
			maxX -= 1
			
		minY += 1
		if minY < maxY:
			maxY -= 1
	
	return shape
		
func normalize_shape(shape):
	var minX = INF
	var minY = INF
	
	# find the smallest x and y values in the shape
	for slot in shape:
		if slot.x < minX:
			minX = slot.x
		if slot.y < minY:
			minY = slot.y
	
	for index in shape.size():
		shape[index].x -= minX
		shape[index].y -= minY
	
	return shape

func randomize_rotation(item, rng: RandomNumberGenerator):
	var rotation_count = rng.randi_range(0,3)
	
	while(rotation_count):
		item = rotate_item(item, true)
		rotation_count -= 1
		
	return item
		
