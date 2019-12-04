using System;
using Godot;

public class WaterPlane : Spatial 
{
	// Subnodes
	[Subnode("WaterPlane")]	private MeshInstance WaterPlaneMesh;
	[Subnode("MoveToTop")] 	private Tween MoveToTopTween;

	// Signals
	[Signal] delegate void WaterAtTop();

	// Funcs
	public override void _Ready()
	{
		ShaderMaterial shaderMat = (ShaderMaterial)WaterPlaneMesh.GetSurfaceMaterial(0);
		shaderMat.SetShaderParam("waterTexture", GD.Load<Texture>("res://Textures/SimpleCaustics.png"));
		GameState.Instance._WaterSystem = this;
	}

	public override void _Process(float delta)
	{
		ShaderMaterial shaderMat = (ShaderMaterial)WaterPlaneMesh.GetSurfaceMaterial(0);
		shaderMat.SetShaderParam("dayNightValue", GameState.Instance.NormalizedDayNightCycleTime);
		
		float turb = Mathf.Pow(Mathf.Abs(GameState.Instance.NormalizedDayNightCycleTime - 0.5f) * 2.0f, 1.5f);
		shaderMat.SetShaderParam("waterTurbulence", turb);
	}

	public override void _ExitTree()
	{
		GameState.Instance._WaterSystem = null;
	}

	public async void AnimateToHeight(float targetHeight, float duration = 1.0f)
	{
		MoveToTopTween.InterpolateProperty(WaterPlaneMesh, "translation:y", 0.0f, targetHeight, duration, Tween.TransitionType.Quad, Tween.EaseType.InOut);
		MoveToTopTween.Start();

		await ToSignal(MoveToTopTween, "tween_all_completed");
		EmitSignal(nameof(WaterAtTop));		
	}

	public async void AnimateAway(float duration = 1.0f)
	{
		MoveToTopTween.InterpolateProperty(WaterPlaneMesh, "translation:y", null, 0.0f, duration, Tween.TransitionType.Quad, Tween.EaseType.InOut);
		MoveToTopTween.Start();

		await ToSignal(MoveToTopTween, "tween_all_completed");
	}

}