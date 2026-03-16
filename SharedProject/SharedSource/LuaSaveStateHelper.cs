using System.Text.Json.Serialization;
using System.Xml.Linq;
using Barotrauma;
using Barotrauma.Items.Components;
using Barotrauma.LuaCs;

namespace Mechtrauma;

public class LuaSaveStateHelper : ItemComponent
{
    public static readonly string Event_OnSave = $"{nameof(Mechtrauma.LuaSaveStateHelper)}::OnSave";
    public static readonly string Event_OnLoad = $"{nameof(Mechtrauma.LuaSaveStateHelper)}::OnLoad";
    
    public string Name { get; private set; }
    
    public LuaSaveStateHelper(Item item, ContentXElement element) : base(item, element)
    {
        InitializeXml(element);
    }

    private void InitializeXml(ContentXElement? element)
    {
        if (element is null)
        {
            ModUtils.Logging.PrintError($"{nameof(Mechtrauma.LuaSaveStateHelper)}::InitializeXml() | Element is null!");
            return;
        }

        Name = element.GetAttributeString("Name", string.Empty);
    }

    public override void Load(ContentXElement componentElement, bool usePrefabValues, IdRemap idRemap, bool isItemSwap)
    {
        base.Load(componentElement, usePrefabValues, idRemap, isItemSwap);
        ContentXElement? element = componentElement.GetChildElement("LuaSaveStateHelper");
        LuaCsSetup.Instance.Hook.Call(Event_OnLoad, this, element); // componentElement can be null.
    }

    public override XElement Save(XElement parentElement)
    {
        base.Save(parentElement);
        XElement element = new XElement("LuaSaveStateHelper");
        LuaCsSetup.Instance.Hook.Call(Event_OnSave, this, element);  
        parentElement.Add(element);
        return element;
    }
}