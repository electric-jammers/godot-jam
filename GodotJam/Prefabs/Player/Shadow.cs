using System;
using Godot;

public class Shadow : CSGBox
{
	public override void _Process(float delta)
	{
		ShaderMaterial shaderMat = Material as ShaderMaterial;
		shaderMat.SetShaderParam("PlayerY", Translation.y);
	}
}