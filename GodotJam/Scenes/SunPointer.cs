using System;
using Godot;

public class SunPointer : DirectionalLight
{
	[Export] bool IsSun = true;

	float InitialLightEnergy = 1.0f;

	public override void _Ready()
	{
		InitialLightEnergy = LightEnergy;
	}

	public override void _Process(float delta)
	{
		LookAt(Vector3.Zero, Vector3.Up);
		
		float time = GameState.Instance.NormalizedDayNightCycleTime % 1.0f;
		float stageTime = GameState.Instance.NormalizedStageTime;

		if ((IsSun && (time > 0.75f || time < 0.25f)) ||
			(!IsSun && (time > 0.25f && time < 0.75f)))
		{
			LightEnergy = 0.0f;
			ShadowEnabled = false;
		}
		else
		{
			LightEnergy = Mathf.Pow(Mathf.Lerp(0.0f, InitialLightEnergy, Mathf.Clamp(1.0f - Mathf.Abs(stageTime - 0.5f) * 2.0f, 0.0f, 1.0f)), 0.2f);
			ShadowEnabled = true;
		}

		//if isSun:
		//	print(String(light_energy))
	}
} 
