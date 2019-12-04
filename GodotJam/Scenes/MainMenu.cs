using System;
using Godot;

public class MainMenu : Control
{
	public override void _Ready()
	{
		GetNode<Button>("VBoxContainer/StartButton").GrabFocus();
	}
	private void OnStartButtonPressed()
	{
		GetTree().ChangeScene("res://Scenes/MainScene.tscn");
	}
	private void OnQuitButtonPressed()
	{
		GetTree().Quit();
	}
}