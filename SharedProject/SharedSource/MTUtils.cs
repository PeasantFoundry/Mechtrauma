using Barotrauma;
using Barotrauma.Items.Components;
using HarmonyLib;

namespace Mechtrauma;

public static class MTUtils
{
    private static readonly MethodInfo MGetComponentsByNameInternal =
        AccessTools.DeclaredMethod(typeof(Barotrauma.Item), "GetComponent");
    
    public static object GetComponentsByName(Item item, string name)
    {
        throw new NotImplementedException();
    }
}