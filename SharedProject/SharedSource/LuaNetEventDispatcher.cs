using Barotrauma;
using Barotrauma.Items.Components;
using System.ComponentModel;

namespace Mechtrauma;

public partial class LuaNetEventDispatcher : ItemComponent
{
    public static readonly string Event_ServerRead = "Mechtrauma.LuaNetEventDispatcher::ServerRead";
    public static readonly string Event_ServerWrite = "Mechtrauma.LuaNetEventDispatcher::ServerWrite";
    public static readonly string Event_ClientRead = "Mechtrauma.LuaNetEventDispatcher::ClientRead";
    public static readonly string Event_ClientWrite = "Mechtrauma.LuaNetEventDispatcher::ClientWrite";
   
    public string Name { get; set; }
    
    public LuaNetEventDispatcher(Item item, ContentXElement element) : base(item, element)
    {
        InitializeXml(element);
    }

    public void InitializeXml(ContentXElement element)
    {
        if (element is null)
            return;

        Name = element.GetAttributeString("Name", string.Empty);
    }

    public virtual partial void SendEvent();
}