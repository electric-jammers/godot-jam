using System;
using Godot;
using Godot.Collections;

public class BirdEffect : Spatial
{
	[Subnode] private AnimationPlayer AnimationPlayer;

	[Export] public int BirdsCount = 4;
	[Export] public float Radius = 1;
	[Export] public float Speed = 1;

	private PackedScene BirdScene;
	private Array<Spatial> Birds = new Array<Spatial>();


	public override void _Ready()
	{
		base._Ready();

		this.FindSubnodes();
		BirdScene = GD.Load<PackedScene>("res://Scenes/birdie.tscn");		
	}

	public override void _Process(float delta)
	{
		base._Process(delta);

		Rotation = new Vector3
		{
			x = Rotation.x,
			y = Rotation.y + delta * Speed,
			z = Rotation.z,
		};
	}

	public void SetBirdsCount(int count)
	{
		foreach (Spatial bird in Birds)
		{
			bird.QueueFree();
		}
		Birds.Clear();

		for (int i = 0; i < count; i++)
		{
			Spatial bird = (Spatial)BirdScene.Instance();

			float phase = ((Mathf.Pi * 2.0f) / count) * i;

			bird.RotateY(phase);
			bird.Translate(new Vector3(Radius, 0.0f, 0.0f));
			bird.Scale = new Vector3(0.2f, 0.2f, 0.2f);

			AddChild(bird);
			Birds.Add(bird);
		}
	}

	public void Play()
	{
		AnimationPlayer.Play("Fade");
	}
}
