using System;
using Godot;

public class ButtonWithSound : Button
{
	[Subnode("AudioStreamPlayer")] 
	private AudioStreamPlayer SoundPlayer;

	public override void _Ready()
	{
		base._Ready();
		this.FindSubnodes();
	}

	private void OnButtonPressed()
	{
		SoundPlayer.Play(0.3f);
	}
}