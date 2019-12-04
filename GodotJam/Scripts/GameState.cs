using System;
using Godot;

public class GameState : Node 
{
	// Singleton
	public static GameState Instance { get { return (Engine.GetMainLoop() as SceneTree).Root.GetNode<GameState>("/root/GameState"); } }

	// Emitted when stage changes
	[Signal] delegate void StageChanged(GameStage newStage);
	[Signal] delegate void PlayerDied(int playerIndex);
	[Signal] delegate void PlayerHit(int playerIndex, Vector3 hitVelocity);
	[Signal] delegate void GameOver(int winningPlayerIndex);

	public enum GameStage {
		Frontend,

		Day,
		Night,

		GameOver
	}

	private const float STAGE_LEN = 5.0f;

	private float CurrentTime = 0.0f;
	private float TimeInStage = 0.0f;
	private float CurrentWaterHeight = 2.0f;
	private byte CurrentWaterDamage = 0x05;

	public GameStage Stage { get; private set; } = GameStage.Frontend;

	public SandSystem _SandSystem;
	public SandSystem SandSystem { get => _SandSystem; }
	public WaterPlane _WaterSystem;
	public WaterPlane WaterSystem { get => _WaterSystem; }

	// Player death handling
	const float GAME_OVER_TIMER_DURATION = 1.0f;

	private Timer GameOverTimer = new Timer();
	private bool[] AlivePlayers = { true, true };
	public int[] PlayersWinCount = { 0, 0 };
	
	public override void _Ready()
	{
		GameOverTimer.OneShot = true;
		GameOverTimer.WaitTime = GAME_OVER_TIMER_DURATION;
		GameOverTimer.Connect("timeout", this, nameof(GameOverTimerTimeout));
		AddChild(GameOverTimer);
	}

	public override void _Process(float delta)
	{
		if (_WaterSystem == null)
		{
			return;
		}

		CurrentTime += delta;
		TimeInStage += delta;

		if ((Stage == GameStage.Day || Stage == GameStage.Night) && NormalizedStageTime > 1.0f)
		{
			EnterStage(Stage == GameStage.Day ? GameStage.Night : GameStage.Day);
		}
	}

	// 0 = midnight, 0.5 = noon, 1 = midnight
	public float NormalizedDayNightCycleTime 
	{
		get 
		{
			switch (Stage)
			{
				case GameStage.Day:
					return 0.25f + (NormalizedStageTime/ 2.0f);
				case GameStage.Night:
					return (0.75f + (NormalizedStageTime/ 2.0f)) % 1.0f;
				default:
					return 0.0f;
			}
		}
	}

	public float NormalizedStageTime { get => TimeInStage / STAGE_LEN; }

	public void EnterStage(GameStage newGameStage)
	{
		if (Stage == newGameStage)
		{
			return;
		}

		if (newGameStage == GameStage.Day && Stage == GameStage.Night)
		{
			_WaterSystem.AnimateAway();
		}

		if (newGameStage == GameStage.Night)
		{
			_WaterSystem.AnimateToHeight(CurrentWaterHeight);
			_SandSystem.DamageAllSandUpToHeight((int)CurrentWaterHeight, CurrentWaterDamage); //FIXME: should divide by cell size?
		}

		Stage = newGameStage;
		EmitSignal(nameof(StageChanged), newGameStage);

		if (newGameStage == GameStage.GameOver)
		{
			MeshInstance dm0 = _SandSystem.Dummies[0];
			dm0.Visible = false;

			MeshInstance dm1 = _SandSystem.Dummies[1];
			dm1.Visible = false;
		}

		TimeInStage = 0.0f;
	}

	private SandSystem GetSandSystem()
	{
		return _SandSystem;
	}

	private void ReportPlayerDeath(int playerIndex)
	{
		AlivePlayers[playerIndex] = false;
		GameOverTimer.Start();

		EmitSignal(nameof(PlayerDied), playerIndex);
	}

	public void ReportPlayerHit(int playerIndex, Vector3 hitForce)
	{
		EmitSignal(nameof(PlayerHit), playerIndex, hitForce);
	}

	private void GameOverTimerTimeout()
	{
		int winningPlayer = -1;

		for (int i = 0; i < AlivePlayers.Length; i++)
		{
			if (AlivePlayers[i])
			{
				winningPlayer = i;
			}
			AlivePlayers[i] = true;
		}

		EnterStage(GameStage.GameOver);
		EmitSignal(nameof(GameOver), winningPlayer);
	}
}