extends RefCounted

static func create_sprite_frames(anim_configs: Array) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
		
	for config in anim_configs:
		var name: String = config["name"]
		var path: String = config["path"]
		var count: int = config["count"]
		var fps: float = config.get("fps", 10.0)
		var loop: bool = config.get("loop", true)
		var frame_w: float = config.get("width", 100.0)
		var frame_h: float = config.get("height", 100.0)
		
		if not frames.has_animation(name):
			frames.add_animation(name)
		frames.set_animation_speed(name, fps)
		frames.set_animation_loop(name, loop)
		
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			for i in range(count):
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = tex
				atlas.region = Rect2(float(i) * frame_w, 0.0, frame_w, frame_h)
				frames.add_frame(name, atlas)
				
	return frames

static func get_archer_frames() -> SpriteFrames:
	return create_sprite_frames([
		{
			"name": "idle",
			"path": "res://asset/character01/character01/Characters(100x100)/Archer/Archer with shadows/Archer_Idle.png",
			"count": 6,
			"fps": 8.0,
			"loop": true
		},
		{
			"name": "walk",
			"path": "res://asset/character01/character01/Characters(100x100)/Archer/Archer with shadows/Archer_Walk.png",
			"count": 8,
			"fps": 12.0,
			"loop": true
		},
		{
			"name": "attack",
			"path": "res://asset/character01/character01/Characters(100x100)/Archer/Archer with shadows/Archer_Attack01.png",
			"count": 9,
			"fps": 15.0,
			"loop": false
		},
		{
			"name": "hurt",
			"path": "res://asset/character01/character01/Characters(100x100)/Archer/Archer with shadows/Archer_Hurt.png",
			"count": 4,
			"fps": 10.0,
			"loop": false
		},
		{
			"name": "death",
			"path": "res://asset/character01/character01/Characters(100x100)/Archer/Archer with shadows/Archer_Death.png",
			"count": 4,
			"fps": 8.0,
			"loop": false
		}
	])

static func get_bat_frames() -> SpriteFrames:
	return create_sprite_frames([
		{
			"name": "fly",
			"path": "res://asset/character01/character01/Characters(100x100)/Bat/Bat with shadows/Bat_Flying.png",
			"count": 6,
			"fps": 10.0,
			"loop": true
		},
		{
			"name": "attack",
			"path": "res://asset/character01/character01/Characters(100x100)/Bat/Bat with shadows/Bat_Attack01.png",
			"count": 6,
			"fps": 12.0,
			"loop": false
		},
		{
			"name": "hurt",
			"path": "res://asset/character01/character01/Characters(100x100)/Bat/Bat with shadows/Bat_Hurt.png",
			"count": 4,
			"fps": 10.0,
			"loop": false
		},
		{
			"name": "death",
			"path": "res://asset/character01/character01/Characters(100x100)/Bat/Bat with shadows/Bat_Death.png",
			"count": 4,
			"fps": 8.0,
			"loop": false
		}
	])
