using Barotrauma;
using Barotrauma.Items.Components;
using HarmonyLib;

namespace Mechtrauma;

public static class MTUtils
{
    private static readonly Dictionary<string, System.Type> TypeLookupRef = new();

    public static object GetComponentByName(Item item, string name)
    {
        Type t;
        if (!TypeLookupRef.ContainsKey(name))
        {
            var type = AssemblyUtils.GetAllTypesInLoadedAssemblies()
                .FirstOrDefault(t => t?.FullName?.EndsWith(name) ?? t?.Name.EndsWith(name) ?? false, null);
            if (type is null)
                return null!;
            TypeLookupRef[name] = type;
            t = type;
        }
        else
        {
            t = TypeLookupRef[name];
        }

        if (item.componentsByType.ContainsKey(t))
        {
            return item.componentsByType[t];
        }
        return item.Components.FirstOrDefault(c => c?.GetType().IsAssignableTo(t) ?? false, null)!;
    }

    public static void PurgeTypeCache() => TypeLookupRef.Clear();
}