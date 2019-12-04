using System;
using Godot;
using Godot.Collections;

public class RandomizedStreamPlayer : AudioStreamPlayer
{
	[Export] Array<AudioStream> StreamArray = new Array<AudioStream>();
	[Export] bool Looping = false;
	[Export] float LoopDuration = 10.0f;
	[Export] float RandomSpread = 0.5f;

	[Subnode] Timer Timer;

	public override void _Ready()
	{
		this.FindSubnodes();

		GD.Randomize();
		if (Looping)
		{
			Timer.Start(LoopDuration * RandomSpread);
		}		
	}

	public new void Play(float fromPosition = 0.0f)
	{
		int soundIndex = (int)(GD.Randi() % StreamArray.Count);
		Stream = StreamArray[soundIndex];		

		if (Looping)
		{
			float newTime = LoopDuration + 0.1f;
			
			LoopDuration += (float)GD.RandRange(-RandomSpread, RandomSpread) * LoopDuration;
			Timer.Start(LoopDuration);
		}

		base.Play(fromPosition);
	}

	private void OnTimerTimeout()
	{
		Play();
	}
}