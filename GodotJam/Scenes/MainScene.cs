using System;
using Godot;

class MainScene : Spatial
{
	public override void _Ready()
	{
		GameState.Instance.EnterStage(GameState.GameStage.Day);
		GameState.Instance.Connect("GameOver", this, nameof(OnGameOver));
	}

	public async override void _Input(InputEvent inputEvent)
	{
		if (inputEvent is InputEventKey && ((InputEventKey)inputEvent).Scancode == (int)KeyList.T)
		{
			WaterPlane water = GetNode<WaterPlane>("WaterAnchor");
			water.AnimateToHeight(3.0f);

			await ToSignal(water, "WaterAtTop");
			await ToSignal(GetTree().CreateTimer(1.0f), "timeout");

			water.AnimateAway();
		}
	}

	private void OnGameOver(int winner)
	{
		GetNode<EndGameOverlay>("EndGameOverlay").Display(winner);
	}
}