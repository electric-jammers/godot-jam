using System;
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

	[Subnode("articles/Walking")] 			Particles WalkingParticles;
	[Subnode("articles/Sand")] 				Particles SandParticles;
	[Subnode("articles/Bubbles")] 			Particles BubbleParticles;
	[Subnode("StepTimer")] 					Timer StepTimer;
	[Subnode("PickupTimer")] 				Timer Pickup_recently_timer;

	[Subnode("Mesh/Particles/BirdsEffect")]	AudioStreamPlayer3D BirdsEffect;

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
	private Array<int> CarriedBlocksInfo = new Array<int>();
	
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

		
/*

	var sand_info = sand.extract_sand(action_location)

	if sand_info.size() > 0:
		var new_block = sand_info[0]

		_carried_blocks.push_back(new_block)
		_carried_blocks_info.push_back(sand_info[1])

		var block_collision = new_block.get_node("CollisionShape") as CollisionShape
		block_collision.disabled = true

		new_block.get_parent_spatial().remove_child(new_block)
		new_block.translation = Vector3(0.0, _carried_blocks.size() * (0.1 + SandSystem.BLOCK_SIZE) + 2.0, 0.0)
		add_child(new_block)

		_pickup_recently_timer.start()

		$SandSoundPlayer.play()
		_sand_particles.emitting = true
		_shovel.stop(true)
		_shovel.play("ShovelAnim")



	# Placing
	if Input.is_action_just_pressed("action_place_Player" + str(player_index+1)):
		if not _carried_blocks.empty():
			var in_front = action_location + Vector3(0.0, 10.0, 0.0)
			if sand.add_sand(in_front, _carried_blocks_info.back()):
				_carried_blocks.pop_back().queue_free()
				_carried_blocks_info.pop_back()
				$SandSoundPlayer.play()
				_sand_particles.emitting = true

				_is_animating_shovel = true

	# "Physics"
	if _on_ground:
		if Input.is_action_just_pressed("jump_Player" + str(player_index+1)):
			_velocity.y += JUMP_POWER 
			$JumpSoundPlayer.play()

		_velocity *= 1.0 - GROUND_FRICTION
	else:
		_velocity *= Vector3(1.0 - AIR_FRICTION, 1.0, 1.0 - AIR_FRICTION)
		_velocity += Vector3(0.0, -GRAVITY, 0.0)

	# Getting hit
	if _hit_velocity.length_squared() > 0.01:
		_velocity += _hit_velocity
		_hit_velocity = Vector3()
		_birds_effect.play()

	var new_velocity := move_and_slide(_velocity / 60.0)
	var horizontal_velocity := Vector2(new_velocity.x, new_velocity.z)

	if horizontal_velocity.length_squared() > 0.5 and abs(new_velocity.y) < 0.0001:
		_walking_particles.emitting = true

	# Detect walls and hop up (only if not hopped or collected recently)
	if _step_timer.time_left <= 0.0 and _pickup_recently_timer.time_left <= 0.0:
		for slide_index in get_slide_count():
			var slide_coll: KinematicCollision = get_slide_collision(slide_index )

			var sand_height_here = GameState.get_sand_system().get_sand_height(translation + Vector3(SandSystem.BLOCK_SIZE, 0.0, SandSystem.BLOCK_SIZE) * 0.5)
			var sand_height_there = GameState.get_sand_system().get_sand_height(_get_pickup_action_location())

			# if player_index == 0:
				# $Mesh/DebugLabel.text = "Hop: " + str(sand_height_here) + " -> " + str(sand_height_there)

			if sand_height_there == sand_height_here + 1:
				_velocity.y += STEP_POWER
				_step_timer.start()
				break

	# Dash
	if _dash_timer.time_left <= 0.0 and Input.is_action_just_pressed("dash_Player" + str(player_index+1)):
		_dash_timer.start()
		_velocity += DASH_POWER * _meshes.transform.basis.z

	# Facing
	if not Input.is_action_pressed("strafe_Player" + str(player_index+1)):
		var ground_velocity = _velocity
		ground_velocity.y = 0.0

		if ground_velocity.length_squared() > 100.0:
			_face_dir(ground_velocity)
	else:
		var look_dir := Vector3()
		look_dir.x = Input.get_action_strength("look_-X_Player" + str(player_index+1)) - Input.get_action_strength("look_+X_Player" + str(player_index+1))
		look_dir.z = Input.get_action_strength("look_-Y_Player" + str(player_index+1)) - Input.get_action_strength("look_+Y_Player" + str(player_index+1))

		if look_dir.length_squared() > 0.5 * 0.5:
			_face_dir(look_dir)

	# Death by drowning
	if translation.y < -4:
		$DrownSoundPlayer.play()
		GameState.report_player_death(player_index)
		while not _carried_blocks.empty():
			_carried_blocks.pop_back().queue_free()
			_carried_blocks_info.pop_back()
		_is_dead = true
		_bubble_particles.emitting = true

*/
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