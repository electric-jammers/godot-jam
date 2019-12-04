using System;
using System.Reflection;

[AttributeUsage(AttributeTargets.Field | AttributeTargets.Property)]
class SubnodeAttribute : System.Attribute
{
	public string NodePath { get; private set; }

	public SubnodeAttribute(string nodePath = null)
	{
		NodePath = nodePath;
	}
}

public static class NodeExtensions
{
	public static void FindSubnodes(this Godot.Node node)
	{
		foreach (PropertyInfo prop in node.GetType().GetProperties(BindingFlags.DeclaredOnly | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance))
        {
			if (prop.GetValue(node) != null)
			{
				continue;
			}

	        SubnodeAttribute Subnode = (SubnodeAttribute)Attribute.GetCustomAttribute(prop, typeof(SubnodeAttribute));
			if (Subnode != null)
			{
				string nodePath = Subnode.NodePath == null ? prop.Name : Subnode.NodePath;
				var subnode = node.GetNode(nodePath);
				prop.SetValue(node, subnode);
			}
        }

		foreach (FieldInfo field in node.GetType().GetFields(BindingFlags.DeclaredOnly | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance))
		{
			if (field.GetValue(node) != null)
			{
				continue;
			}


			SubnodeAttribute Subnode = (SubnodeAttribute)Attribute.GetCustomAttribute(field, typeof(SubnodeAttribute));
			if (Subnode != null)
			{
				string nodePath = Subnode.NodePath == null ? field.Name : Subnode.NodePath;
				var subnode = node.GetNode(nodePath);
				field.SetValue(node, subnode);
			}
		}
	}
}
