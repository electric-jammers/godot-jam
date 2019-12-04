using System;
using Godot;
using Godot.Collections;

public class SandSystem : Node
{
	private SandType[] SandVoxels = new SandType[SIZE_X * SIZE_Y * SIZE_Z];
	private byte[] Health = new byte[SIZE_X * SIZE_Y * SIZE_Z];

	private const int SIZE_X = 26;
	private const int SIZE_Y = 16;
	private const int SIZE_Z = 16;

	public const float BLOCK_SIZE = 1.5f;

	private Vector3 RootPosition = new Vector3(12.5f, 0.0f, 7.5f) * BLOCK_SIZE;

	public enum SandType : byte
	{
		None,
		SoftSand,
		HardSand,
		Rock,
		Bedrock
	}

	private Dictionary<int, Spatial> CubeSpatialDict = new Dictionary<int, Spatial>();
	private Array<int> LocationsToDrop = new Array<int>();

	private PackedScene SoftSandScene = GD.Load<PackedScene>("res://Prefabs/SandSystem/SoftSand.tscn");
	private PackedScene HardSandScene = GD.Load<PackedScene>("res://Prefabs/SandSystem/HardSand.tscn");
	private PackedScene RockScene = GD.Load<PackedScene>("res://Prefabs/SandSystem/Rock.tscn");
	private PackedScene BedrockScene = GD.Load<PackedScene>("res://Prefabs/SandSystem/Bedrock.tscn");
	private PackedScene DummyScene = GD.Load<PackedScene>("res://Prefabs/SandSystem/Dummy.tscn") ;

	public Dictionary<int, MeshInstance> Dummies = new Dictionary<int, MeshInstance>();

	public override void _Ready()
	{
		for (int i = 0; i < SandVoxels.Length; i++)
		{
			SandVoxels[i] = SandType.None;
			Health[i] = 0;
		}

		// Bedrock
		for (int z = 0; z < SIZE_Z; z++)
		{
			for (int x = 0; x < SIZE_X; x++)
			{
				AddSand(new Vector3(x * BLOCK_SIZE, 0, z * BLOCK_SIZE) - RootPosition, SandType.Rock);
			}	
		}

		OpenSimplexNoise noise = new OpenSimplexNoise();
		noise.Seed = (int)GD.Randi();
		noise.Octaves = 3;
		noise.Period = 30.0f;
		noise.Persistence = 0.0f;

		// Initial land
		for (int z = 0; z < SIZE_Z; z++)
		{
			for (int x = 0; x < SIZE_X; x++)
			{
				float n = noise.GetNoise2d(x, z) * 5.0f + 5.0f;
				for (int ni = 0; ni < n; ni++)
				{
					float dn = n - ni - 1;
					AddSand(new Vector3(x * BLOCK_SIZE, 1 + ni, z * BLOCK_SIZE) - RootPosition, dn > 3.0f ? SandType.Rock : (dn > 1.0f ? SandType.HardSand : SandType.SoftSand));
				}
			}	
		}
		GameState.Instance._SandSystem = this;
	}

	public override void _ExitTree()
	{
		GameState.Instance._SandSystem = null;
	}

	public override void _Process(float delta)
	{
		CallDeferred(nameof(DropSand));
	}

	private Vector3 IndexToWorldPosition(int index)
	{
		int y = index / (SIZE_X * SIZE_Z);
		int z = (index - (y * SIZE_X * SIZE_Z)) / SIZE_X;
		int x = index - ((y * SIZE_X * SIZE_Z) + (z * SIZE_X));

		Vector3 result = new Vector3((float)x, (float)y, (float)z);
		return (result * BLOCK_SIZE) - RootPosition;
	}

	private int PositionToIndex(Vector3 position)
	{
		position = (position + RootPosition) / BLOCK_SIZE;

		int x = (int)position.x;
		int y = (int)position.y;
		int z = (int)position.z;
		return _IntsToIndex(x, y, z);
	}

	private int _IntsToIndex(int x, int y, int z)
	{
		return (int)x + ((int)y * SIZE_X * SIZE_Z) + ((int)z * (SIZE_X));
	}

	public float GetSandHeight(Vector3 worldPos)
	{
		worldPos = (worldPos + RootPosition) / BLOCK_SIZE;

		int x = (int)worldPos.x;
		int z = (int)worldPos.z;

		for (int y = 0; y < SIZE_Y; y++)
		{
			int positionIndex = _IntsToIndex(x, y, z);
			if (positionIndex < 0 || positionIndex >= SandVoxels.Length)
			{
				//GD.Print($"Trying to get sand height out of bounds at {x}, {z}");
				return -1.0f;
			}

			if (SandVoxels[positionIndex] == SandType.None)
			{
				return (float)y;
			}
		}

		return (float)SIZE_Y;
	}

	public void DamageSand(Vector3 position, byte damageAmount)
	{
		int positionIndex = PositionToIndex(position);
		_DamageSand(positionIndex, damageAmount);
	}
	private void _DamageSand(int positionIndex, byte damageAmount)
	{
		if (positionIndex < 0 || positionIndex >= SandVoxels.Length)
		{
			//GD.Print($"Trying to damage sand out of bounds at {x}, {z}");
			return;
		}

		if (SandVoxels[positionIndex] == SandType.None)
		{
			return;
		}

		byte healthValue = (byte)(Health[positionIndex] - damageAmount);
		if (healthValue <= 0x00)
		{
			Health[positionIndex] = 0x00;
		}
		else
		{
			Health[positionIndex] = healthValue;
		}
	}

	public void DamageAllSandUpToHeight(int maxHeight, byte damageAmount)
	{
		for (int y = 0; y < maxHeight; y++)
		{
			for (int z = 0; z < SIZE_Z; z++)
			{
				for (int x = 0; x < SIZE_X; x++)
				{
					int positionIndex = _IntsToIndex(x, y, z);	
					_DamageSand(positionIndex, damageAmount);
				}
			}
		}
	}

	public bool AddSand(Vector3 position, SandType typeOfSand)
	{
		if (typeOfSand == SandType.None)
		{
			//GD.Print($"Trying to add sand out of bounds at {x}, {z}");
			return false;
		}

		int positionIndex = PositionToIndex(position);
		if (positionIndex < 0 || positionIndex >= SandVoxels.Length)
		{
			//GD.Print($"Trying to add sand out of bounds at {x}, {z}");
			return false;
		}		

		if (SandVoxels[positionIndex] != SandType.None)
		{
			//GD.Print($"Replacing sand that is already there! At {x}, {z}");
			return false;
		}

		Vector3 nextPositionToCheck = position;
		while (nextPositionToCheck.y > 0.0f)
		{
			nextPositionToCheck = new Vector3
			{
				x = nextPositionToCheck.x,
				y = nextPositionToCheck.y - BLOCK_SIZE, //TODO: check this?!
				z = nextPositionToCheck.z,
			};

			int nextPositionIndexToCheck = PositionToIndex(nextPositionToCheck);
			if (SandVoxels[nextPositionIndexToCheck] != SandType.None)
			{
				break;
			}

			positionIndex = nextPositionIndexToCheck;
			position = nextPositionToCheck;
		}

		Spatial cube = null;
		byte initialHealth = 0x0A; //10

		switch (typeOfSand)
		{
			case SandType.SoftSand:
				cube = (Spatial)SoftSandScene.Instance();
				initialHealth = 0x0A; // 10
				break;
			case SandType.HardSand:
				cube = (Spatial)HardSandScene.Instance();
				initialHealth = 0x14; // 20
				break;
			case SandType.Rock:
				cube = (Spatial)RockScene.Instance();
				initialHealth = 0x1E; // 30
				break;
			case SandType.Bedrock:
				cube = (Spatial)BedrockScene.Instance();
				initialHealth = 0xFF;
				break;
		}

		if (cube != null)
		{
			SandVoxels[positionIndex] = typeOfSand;
			Health[positionIndex] = initialHealth;
			AddChild(cube);

			CubeSpatialDict[positionIndex] = cube;
			cube.Translation = IndexToWorldPosition(positionIndex);
		}

		return true;
	}

	public MeshInstance DrawDummy(Vector3 position, int dummyIndex)
	{
		int positionIndex = PositionToIndex(position);
		Vector3 snappedPosition = IndexToWorldPosition(positionIndex);

		if (!Dummies.ContainsKey(dummyIndex))
		{
			MeshInstance newDummy = (MeshInstance)DummyScene.Instance();
			AddChild(newDummy);

			Dummies[dummyIndex] = newDummy;
		}

		MeshInstance dummy = Dummies[dummyIndex];
		dummy.Visible = true;
		dummy.Translation = new Vector3
		{
			x = snappedPosition.x,
			y = snappedPosition.y + BLOCK_SIZE,
			z = snappedPosition.z,
		};
		return dummy;
	}

	public void RemoveSand(Vector3 position)
	{
		int positionIndex = PositionToIndex(position);
		_RemoveSand(positionIndex);
	}

	private void _RemoveSand(int positionIndex)
	{
		var sandData = _ExtractSand(positionIndex);
		if (sandData != null)
		{
			sandData.Item1.QueueFree();
		}
	}

	public Tuple<Spatial, SandType> ExtractSand(Vector3 position) 
	{
		int positionIndex = PositionToIndex(position);
		return _ExtractSand(positionIndex);
	}

	private Tuple<Spatial, SandType> _ExtractSand(int positionIndex)
	{
		if (positionIndex < 0 || positionIndex >= SandVoxels.Length)
		{
			//GD.Print($"Trying to remove sand out of bounds at {x}, {z}");
			return null;
		}

		SandType sandType = SandVoxels[positionIndex];
		if (sandType == SandType.None || sandType == SandType.Bedrock)
		{
			//GD.Print("No sand to extract here!");
			return null;
		}

		SandVoxels[positionIndex] = SandType.None;

		if (CubeSpatialDict.ContainsKey(positionIndex))
		{
			Spatial cube = CubeSpatialDict[positionIndex];
			CubeSpatialDict.Remove(positionIndex);
			LocationsToDrop.Add(positionIndex);

			return new Tuple<Spatial, SandType>(cube, sandType);
		}

		return null;
	}

	private void DropSand()
	{
		foreach (int locationToDrop in LocationsToDrop)
		{
			int yLowest = locationToDrop / (SIZE_X * SIZE_Z);
			int z = (locationToDrop - (yLowest * SIZE_X * SIZE_Z)) / SIZE_X;
			int x = locationToDrop - ((yLowest * SIZE_X * SIZE_Z) + (z * SIZE_X));

			for (int y = yLowest; y < SIZE_Y; y++)
			{
				int index = _IntsToIndex(x, y, z);
				if (SandVoxels[index] == SandType.None)
				{
					continue;
				}

				for (int yBelow = y - 1; yBelow < yLowest-1; yBelow--)
				{
					if (yLowest < 0)
					{
						continue;
					}

					int belowIndex = _IntsToIndex(x, yBelow, z);
					if (SandVoxels[belowIndex] == SandType.None)
					{
						break;
					}

					SandVoxels[belowIndex] = SandVoxels[index];
					Health[belowIndex] = Health[index];
					CubeSpatialDict[belowIndex] = CubeSpatialDict[index];
					
					SandVoxels[index] = SandType.None;
					Health[index] = 0x00;
					CubeSpatialDict.Remove(index);

					//TODO: animate?
					CubeSpatialDict[belowIndex].Translation = IndexToWorldPosition(belowIndex);
					index = belowIndex;
				}
			}
		}

		LocationsToDrop.Clear();
	}
}