using System;
using Godot;

public class DayNight : Spatial
{
	public override void _Process(float delta)
	{
		Rotation = new Vector3
		{
			x = 0.0f,
			y = 0.0f,
			z = GameState.Instance.NormalizedDayNightCycleTime * Mathf.Pi * 2.0f
		};
	}
}