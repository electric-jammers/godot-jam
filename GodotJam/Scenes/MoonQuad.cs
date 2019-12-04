using System;
using Godot;

public class MoonQuad : MeshInstance
{
	public override void _Process(float delta)
	{
		ShaderMaterial shaderMat = (ShaderMaterial)GetSurfaceMaterial(0);
		shaderMat.SetShaderParam("dayNightValue", GameState.Instance.NormalizedDayNightCycleTime);
	}
}