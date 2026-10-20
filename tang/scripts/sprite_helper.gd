extends RefCounted

static var _frames_cache: Dictionary = {}

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
	if _frames_cache.has("archer"):
		return _frames_cache["archer"]
	var f := create_sprite_frames([
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
	_frames_cache["archer"] = f
	return f

static func get_bat_frames() -> SpriteFrames:
	if _frames_cache.has("bat"):
		return _frames_cache["bat"]
	var f := create_sprite_frames([
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
	_frames_cache["bat"] = f
	return f

static func get_orc_frames() -> SpriteFrames:
	if _frames_cache.has("orc"):
		return _frames_cache["orc"]
	var f := create_sprite_frames([
		{
			"name": "idle",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc/Orc with shadows/Orc_Idle.png",
			"count": 6,
			"fps": 8.0,
			"loop": true
		},
		{
			"name": "walk",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc/Orc with shadows/Orc_Walk.png",
			"count": 8,
			"fps": 10.0,
			"loop": true
		},
		{
			"name": "attack",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc/Orc with shadows/Orc_Attack01.png",
			"count": 6,
			"fps": 12.0,
			"loop": false
		},
		{
			"name": "attack02",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc/Orc with shadows/Orc_Attack02.png",
			"count": 6,
			"fps": 12.0,
			"loop": false
		},
		{
			"name": "hurt",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc/Orc with shadows/Orc_Hurt.png",
			"count": 4,
			"fps": 10.0,
			"loop": false
		},
		{
			"name": "death",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc/Orc with shadows/Orc_Death.png",
			"count": 4,
			"fps": 8.0,
			"loop": false
		}
	])
	_frames_cache["orc"] = f
	return f

static func get_orc_rider_frames() -> SpriteFrames:
	if _frames_cache.has("orc_rider"):
		return _frames_cache["orc_rider"]
	var f := create_sprite_frames([
		{
			"name": "idle",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc rider/Orc rider with shadows/Orc rider_Idle.png",
			"count": 6,
			"fps": 8.0,
			"loop": true
		},
		{
			"name": "walk",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc rider/Orc rider with shadows/Orc rider_Walk.png",
			"count": 8,
			"fps": 12.0,
			"loop": true
		},
		{
			"name": "attack",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc rider/Orc rider with shadows/Orc rider_Attack01.png",
			"count": 8,
			"fps": 14.0,
			"loop": false
		},
		{
			"name": "attack02",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc rider/Orc rider with shadows/Orc rider_Attack02.png",
			"count": 9,
			"fps": 14.0,
			"loop": false
		},
		{
			"name": "attack03",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc rider/Orc rider with shadows/Orc rider_Attack03.png",
			"count": 11,
			"fps": 15.0,
			"loop": false
		},
		{
			"name": "hurt",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc rider/Orc rider with shadows/Orc rider_Hurt.png",
			"count": 4,
			"fps": 10.0,
			"loop": false
		},
		{
			"name": "death",
			"path": "res://asset/character01/character01/Characters(100x100)/Orc rider/Orc rider with shadows/Orc rider_Death.png",
			"count": 4,
			"fps": 8.0,
			"loop": false
		}
	])
	_frames_cache["orc_rider"] = f
	return f

static func get_wind_gust_frames() -> SpriteFrames:
	if _frames_cache.has("wind_gust"):
		return _frames_cache["wind_gust"]
	
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	
	frames.add_animation("gust")
	frames.set_animation_speed("gust", 18.0)
	frames.set_animation_loop("gust", false)
	
	for i in range(9):
		var num_str := "%04d" % i
		var path := "res://asset/directional_smoke_burst_005_large_gray/frame" + num_str + ".png"
		var tex := load(path) as Texture2D
		if tex != null:
			frames.add_frame("gust", tex)
			
	_frames_cache["wind_gust"] = frames
	return frames

static func get_typhoon_frames() -> SpriteFrames:
	if _frames_cache.has("typhoon"):
		return _frames_cache["typhoon"]
	
	var frames: SpriteFrames = SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	
	frames.add_animation("typhoon")
	frames.set_animation_speed("typhoon", 30.0)
	frames.set_animation_loop("typhoon", false)
	
	for i in range(31):
		var num_str := "%04d" % i
		var path := "res://asset/fanfx2_wind_spell_large_white/frame" + num_str + ".png"
		var tex := load(path) as Texture2D
		if tex != null:
			frames.add_frame("typhoon", tex)
			
	_frames_cache["typhoon"] = frames
	return frames

static func get_heal_effect_frames() -> SpriteFrames:
	if _frames_cache.has("heal_effect"):
		return _frames_cache["heal_effect"]
	
	var frames: SpriteFrames = create_sprite_frames([
		{
			"name": "heal",
			"path": "res://asset/character01/character01/Characters(100x100)/Priest/Magic(projectile)/Priest_Heal_effect.png",
			"count": 4,
			"fps": 10.0,
			"loop": false,
			"width": 100.0,
			"height": 100.0
		}
	])
	_frames_cache["heal_effect"] = frames
	return frames





