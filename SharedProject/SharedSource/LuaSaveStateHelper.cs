using System.Text.Json.Serialization;
using System.Xml.Linq;
using Barotrauma;
using Barotrauma.Items.Components;

namespace Mechtrauma;

public class LuaSaveStateHelper : ItemComponent
{
    public static readonly string Event_OnSave = $"{nameof(Mechtrauma.LuaSaveStateHelper)}::OnSave";
    public static readonly string Event_OnLoad = $"{nameof(Mechtrauma.LuaSaveStateHelper)}::OnLoad";
    
    public LuaSaveStateHelper(Item item, ContentXElement element) : base(item, element)
    {
    }

    public override void Load(ContentXElement componentElement, bool usePrefabValues, IdRemap idRemap)
    {
        base.Load(componentElement, usePrefabValues, idRemap);
        ContentXElement? element = componentElement.GetChildElement("LuaSaveStateHelper");
        GameMain.LuaCs.Hook.Call(Event_OnLoad, this, element); // componentElement can be null.
    }

    public override XElement Save(XElement parentElement)
    {
        XElement baseElement = base.Save(parentElement);
        XElement element = new XElement("LuaSaveStateHelper");
        GameMain.LuaCs.Hook.Call(Event_OnLoad, this, element);
        parentElement.Add(element);
        return element;
    }
}