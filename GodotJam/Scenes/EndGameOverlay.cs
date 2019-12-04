using System;
using Godot;

public class EndGameOverlay : Control
{
	[Subnode("ColorRect/MarginContainer/VBoxContainer/HBoxContainer2/GreenScore")]
	private Label GreenLabel;
	[Subnode("ColorRect/MarginContainer/VBoxContainer/HBoxContainer2/RedScore")]
	private Label RedLabel;
	[Subnode("ColorRect/MarginContainer/VBoxContainer/Label")]
	private Label Label;
	
	public override void _Ready()
	{
		this.FindSubnodes();
	}

	public void Display(int winner)
	{
		if (winner == -1)
		{
			int tieMessage = (int)(GD.Randi() % 3);
			switch (tieMessage)
			{
				case 0: Label.Text = "It's a tie!"; break;
				case 1: Label.Text = "No winners today!"; break;
				case 2: Label.Text = "Well that's sad, no winners!"; break;
			}
		}
		else
		{
			int loser = 1 - winner;
			
			// Score labels
			GameState.Instance.PlayersWinCount[winner] += 1;
			GreenLabel.Text = $"{GameState.Instance.PlayersWinCount[0]}";
			RedLabel.Text = $"{GameState.Instance.PlayersWinCount[1]}";

			int tieMessage = (int)(GD.Randi() % 5);
			switch (tieMessage)
			{
				case 0: Label.Text = $"{GetPlayerColor(winner)} completely dominated {GetPlayerColor(loser)}!"; break;
				case 1: Label.Text = $"{GetPlayerColor(winner)} was clearly the better gamer."; break;
				case 2: Label.Text = $"Epic gamer {GetPlayerColor(winner)} destroyed {GetPlayerColor(loser)}!"; break;
				case 3: Label.Text = $"{GetPlayerColor(winner)} outsmarted {GetPlayerColor(loser)}!"; break;
				case 4: Label.Text = $"{GetPlayerColor(loser)} sleeps with the fishes, {GetPlayerColor(winner)} won the game!"; break;
				default: break;
			}
		}

		GetNode<AnimationPlayer>("AnimationPlayer").Play("fade");
		GetNode<Button>("ColorRect/MarginContainer/VBoxContainer/HBoxContainer/PlayAgainButton").GrabFocus();
	}

	string GetPlayerColor(int playerIndex)
	{
		switch (playerIndex)
		{
			case 0: return "Red";
			case 1: return "Green";
			default: return "";
		}
	}

	private void OnPlayAgainButtonPressed() 
	{
		GetTree().ChangeScene("res://Scenes/MainScene.tscn");
	}

	private void OnGoToMenuButtonPressed() 
	{
		GetTree().ChangeScene("res://Scenes/MainMenu.tscn");
	}
}