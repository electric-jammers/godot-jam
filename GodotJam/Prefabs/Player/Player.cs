using System;
using System.Linq;
using Godot;
using Godot.Collections;

public class Player : KinematicBody
{
	// Subnodes
	[Subnode("Mesh")] 						Spatial Meshes;
	[Subnode("ShovelAnimationPlayer")] 		AnimationPlayer Shovel;
	[Subnode("FloorCast")] 					RayCast FloorRaycast;
	[Subnode("DashTimer")] 					Timer DashTimer;

	[Subnode("CamParent")] 					Spatial WinnerCamParent;
	[Subnode("CamParent/Camera")] 			Camera WinnerCam;

	[Subnode("Mesh/Particles/Walking")] 	Particles WalkingParticles;
	[Subnode("Mesh/Particles/Sand")] 		Particles SandParticles;
	[Subnode("Mesh/Particles/Bubbles")] 	Particles BubbleParticles;
	[Subnode("StepTimer")] 					Timer StepTimer;
	[Subnode("PickupTimer")] 				Timer PickupRecentlyTimer;

	[Subnode("Mesh/Particles/BirdsEffect")]	BirdEffect BirdsEffect;

	// Consts
	private const float AIR_FRICTION = 0.25f;
	private const float GROUND_FRICTION = 0.3f;

	private const float SPEED = 200.0f;

	private const float DASH_POWER = 4000.0f;
	private const float STEP_POWER = 1800.0f;
	private const float JUMP_POWER = 3000.0f;

	private const float GRAVITY = 100.0f;

	private const float HIT_FORCE = 11000f;
	private const float HIT_FORCE_UP = 2000f;

	// Public state
	[Export] public int PlayerIndex = 0;

	// Private state
	private Vector3 Velocity = Vector3.Zero;
	private Vector3 HitVelocity = Vector3.Zero;
	private bool Won = false;
	private bool OnGround = false;
	private bool IsDead = false;
	private bool IsAnimatingShovel = false;

	private Array<Spatial> CarriedBlocks = new Array<Spatial>();
	private Array<SandSystem.SandType> CarriedBlocksInfo = new Array<SandSystem.SandType>();
	
	public override void _Ready()
	{
		base._Ready();
		this.FindSubnodes();

		SpatialMaterial material = GD.Load<SpatialMaterial>("res://Materials/CharacterSkin.tres").Duplicate() as SpatialMaterial;

		foreach (var child in Meshes.GetChildren())
		{
			if (child is MeshInstance)
			{
				((MeshInstance)child).SetSurfaceMaterial(0, material);
			}
		}
	
		material.AlbedoColor = new Color[] { new Color(0.698039f, 0.364706f, 0.27451f), new Color(0.356863f, 0.662745f, 0.513726f) }[PlayerIndex];

		GameState.Instance.Connect("GameOver", this, nameof(OnGameOver));
		GameState.Instance.Connect("PlayerHit", this, nameof(OnPlayerHit));
	}

	public override void _PhysicsProcess(float delta)
	{
		if (Won)
		{
			WinnerCamParent.RotateY(delta * 2.0f);
		}		

		if (IsDead || GameState.Instance.Stage == GameState.GameStage.GameOver)
		{
			return;
		}

		// Input
		Vector3 dir = new Vector3
		{
			x = Input.GetActionStrength($"move_-X_Player{PlayerIndex+1}") - Input.GetActionStrength($"move_+X_Player{PlayerIndex+1}"),
			y = 0.0f,
			z = Input.GetActionStrength($"move_-Y_Player{PlayerIndex+1}") - Input.GetActionStrength($"move_+Y_Player{PlayerIndex+1}"),
		};

		Velocity = dir * SPEED;
		OnGround = FloorRaycast.IsColliding();

		SandSystem sand = GameState.Instance.SandSystem;

		// Picking up
		Vector3 actionLocation = GetPickupActionLocation();
		Spatial dummy = sand.DrawDummy(actionLocation, PlayerIndex);

		if (Input.IsActionJustPressed($"action_pickup_Player{PlayerIndex+1}"))
		{
			Area dummyArea = dummy.GetNode<Area>("Area");
			Array<PhysicsBody> overlaps = new Array<PhysicsBody>(dummyArea.GetOverlappingAreas());

			foreach (PhysicsBody overlap in overlaps)
			{
				Player player = overlap as Player;
				if (player != null && player != this)
				{
					GameState.Instance.ReportPlayerHit(player.PlayerIndex, (Meshes.Transform.basis.z * HIT_FORCE) + (Meshes.Transform.basis.y * HIT_FORCE_UP));
					return;
				}
			}
		}

		var sandInfo = sand.ExtractSand(actionLocation);
		if (sandInfo != null)
		{
			Spatial newBlock = sandInfo.Item1;

			CarriedBlocks.Add(newBlock);
			CarriedBlocksInfo.Add(sandInfo.Item2);

			CollisionShape blockCollision = newBlock.GetNode<CollisionShape>("CollisionShape");
			blockCollision.Disabled = true;

			newBlock.GetParentSpatial().RemoveChild(newBlock);
			newBlock.Translation = new Vector3(0.0f, CarriedBlocks.Count * (0.1f + SandSystem.BLOCK_SIZE) + 2.0f, 0.0f);
			AddChild(newBlock);

			PickupRecentlyTimer.Start();

			GetNode<AudioStreamPlayer>("SandSoundPlayer").Play();
			SandParticles.Emitting = true;
			Shovel.Stop(true);
			Shovel.Play("ShovelAnim");
		}

		// Placing
		if (Input.IsActionJustPressed($"action_place_Player{PlayerIndex+1}"))
		{
			if (CarriedBlocks.Count > 0)
			{
				Vector3 inFront = actionLocation + new Vector3(0.0f, 10.0f, 0.0f);
				if (sand.AddSand(inFront, CarriedBlocksInfo.Last()))
				{
					CarriedBlocks.Last().QueueFree();
					CarriedBlocks.RemoveAt(CarriedBlocks.Count-1);
					CarriedBlocksInfo.RemoveAt(CarriedBlocksInfo.Count-1);

					GetNode<AudioStreamPlayer>("SandSoundPlayer").Play();
					SandParticles.Emitting = true;

					IsAnimatingShovel = true;
				}
			}
		}

		// "Physics"
		if (OnGround)
		{
			if (Input.IsActionJustPressed($"jump_Player{PlayerIndex+1}"))
			{
				Velocity.y += JUMP_POWER;
				GetNode<AudioStreamPlayer>("JumpSoundPlayer").Play();
			}
			
			Velocity *= (1.0f - GROUND_FRICTION);
		}
		else
		{
			Velocity *= new Vector3(1.0f - AIR_FRICTION, 1.0f, 1.0f - AIR_FRICTION);
			Velocity += new Vector3(0.0f, -GRAVITY, 0.0f);
		}

		// Getting hit
		if (HitVelocity.LengthSquared() > 0.01)
		{
			Velocity += HitVelocity;
			HitVelocity = Vector3.Zero;
			BirdsEffect.Play();
		}
			
		Vector3 newVelocity = MoveAndSlide(Velocity / 60.0f);
		Vector2 horizontalVelocity = new Vector2(newVelocity.x, newVelocity.z);

		if (horizontalVelocity.LengthSquared() > 0.5f && Mathf.Abs(newVelocity.y) < 0.0001f)
		{
			WalkingParticles.Emitting = true;
		}


		// Detect walls and hop up (only if not hopped or collected recently)
		if (StepTimer.TimeLeft <= 0.0f && PickupRecentlyTimer.TimeLeft <= 0.0f)
		{
			for (int slideIndex = 0; slideIndex < GetSlideCount(); slideIndex++)
			{
				KinematicCollision slideColl = GetSlideCollision(slideIndex);
				
				float sandHeightHere = GameState.Instance.SandSystem.GetSandHeight(Translation + new Vector3(SandSystem.BLOCK_SIZE, 0.0f, SandSystem.BLOCK_SIZE) * 0.5f);
				float sandHeightThere = GameState.Instance.SandSystem.GetSandHeight(GetPickupActionLocation());
				
				// if player_index == 0:
					// $Mesh/DebugLabel.text = "Hop: " + str(sand_height_here) + " -> " + str(sand_height_there)

				if (sandHeightThere == sandHeightHere + 1)
				{
					Velocity.y += STEP_POWER;
					StepTimer.Start();
					break;
				}
			}
		}

		// Dash
		if (DashTimer.TimeLeft <= 0.0f && Input.IsActionJustPressed($"dash_Player{PlayerIndex+1}"))
		{
			DashTimer.Start();
			Velocity += DASH_POWER * Meshes.Transform.basis.z;
		}
			
		// Facing
		if (!Input.IsActionPressed($"strafe_Player{PlayerIndex+1}"))
		{
			Vector3 groundVelocity = Velocity;
			groundVelocity.y = 0.0f;

			if (groundVelocity.LengthSquared() > 100.0f)
			{
				FaceDir(groundVelocity);
			}
		}
		else
		{
			Vector3 lookDir = Vector3.Zero;
			lookDir.x = Input.GetActionStrength($"look_-X_Player{PlayerIndex+1}") - Input.GetActionStrength($"look_+X_Player{PlayerIndex+1}");
			lookDir.z = Input.GetActionStrength($"look_-Y_Player{PlayerIndex+1}") - Input.GetActionStrength($"look_+Y_Player{PlayerIndex+1}");

			if (lookDir.LengthSquared() > 0.5f * 0.5f)
			{
				FaceDir(lookDir);
			}
		}

		// Death by drowning
		if (Translation.y < -4.0f)
		{
			GetNode<AudioStreamPlayer>("DrownSoundPlayer").Play();
			GameState.Instance.ReportPlayerDeath(PlayerIndex);

			while (CarriedBlocks.Count > 0)
			{
				CarriedBlocks.Last().QueueFree();
				CarriedBlocks.RemoveAt(CarriedBlocks.Count-1);
				CarriedBlocksInfo.RemoveAt(CarriedBlocksInfo.Count-1);
			}

			IsDead = true;
			BubbleParticles.Emitting = true;
		}
	}

	private Vector3 GetPickupActionLocation() 
	{
		Vector3 halfBlock = new Vector3(SandSystem.BLOCK_SIZE, 0.0f, SandSystem.BLOCK_SIZE) * 0.5f;
		Vector3 underMe = Translation; // -Vector3(0.0, SandSystem.BLOCK_SIZE, 0.0)
		Vector3 facingDir = Meshes.Transform.basis.z;
		
		if (Mathf.Abs(facingDir.x) > Mathf.Abs(facingDir.z))
		{
			facingDir.z = 0.0f;
		}
		else
		{
			facingDir.x = 0.0f;
		}

		Vector3 actionLocation = underMe + (facingDir * SandSystem.BLOCK_SIZE) + halfBlock;
		return actionLocation;
	}
	
	private void FaceDir(Vector3 dir)
	{
		Vector3 up = Vector3.Up;
		Vector3 fwd = dir.Normalized();
		Vector3 right = fwd.Cross(up).Normalized();

		Meshes.Transform = new Transform
		{
			origin = Meshes.Transform.origin,
			basis = new Basis(right, up, fwd)
		};
	}

	private void OnGameOver(int winner)
	{
		if (PlayerIndex == winner)
		{
			WinnerCam.MakeCurrent();
			Won = true;
		}
	}

	private void OnPlayerHit(int hitPlayer, Vector3 hitVelocity)
	{
		if (PlayerIndex == hitPlayer)
		{
			HitVelocity = hitVelocity;
		}
	}
}