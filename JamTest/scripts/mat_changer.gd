tool
extends CSGMesh

func _process(delta):
	var spatialMat = material as SpatialMaterial
	spatialMat.albedo_color = Color(sin(OS.get_ticks_msec()*0.01)*0.5+0.5, sin(OS.get_ticks_msec()*0.02+2.515)*0.5+0.5, sin(OS.get_ticks_msec()*0.002+0.121561)*0.5+0.5);
