using Barotrauma;
using Barotrauma.Items.Components;
using HarmonyLib;

namespace Mechtrauma;

public static class MTUtils
{
    public static object GetComponentByName(Item item, string name)
    {
        Type t = LuaCsSetup.AssemblyManager.GetTypesByName(name).FirstOrDefault(defaultValue: null)!;

        if (t is null)
            return null!;
        
        if (item.componentsByType.ContainsKey(t))
        {
            return item.componentsByType[t];
        }
        return item.Components.FirstOrDefault(c => c?.GetType().IsAssignableTo(t) ?? false, null)!;
    }
}