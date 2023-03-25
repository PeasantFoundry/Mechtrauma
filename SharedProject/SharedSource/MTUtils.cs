using Barotrauma;
using Barotrauma.Items.Components;
using HarmonyLib;

namespace Mechtrauma;

public static class MTUtils
{
    public static object GetComponentByName(Item item, string name)
    {
#if DEBUG
        Utils.Logging.PrintMessage($"MTUtils::GetComponentByName() | SearchName: { name }");
#endif
        var type = AssemblyUtils.GetAllTypesInLoadedAssemblies()
            .FirstOrDefault(t => t?.FullName?.EndsWith(name) ?? t?.Name.EndsWith(name) ?? false, null);
        if (type is null)
            return null!;
        return item.Components.FirstOrDefault(c =>c?.GetType().IsAssignableTo(type) ?? false, null)!;
    }
}