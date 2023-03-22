using Barotrauma;
using Barotrauma.Items.Components;
using HarmonyLib;

namespace Mechtrauma;

public static class Utils
{
    private static readonly MethodInfo MGetComponentsByNameInternal =
        AccessTools.DeclaredMethod(typeof(Barotrauma.Item), "GetComponent");
    
    public static object GetComponentsByName(Item item, string name)
    {
        try
        {
            Type? baseType = AssemblyUtils
                .GetAllTypesInLoadedAssemblies()
                .FirstOrDefault(t => typeof(ItemComponent).IsAssignableFrom(t) &&
                            (t.FullName?.Equals(name) ?? t.Name.Equals(name)), null);
            if (baseType is null)
                throw new ArgumentException($"Cannot find ItemComponent type by the name of {name} in item {item.Name}");

            return MGetComponentsByNameInternal.MakeGenericMethod(new System.Type[] { baseType }).Invoke(item, null);
        }
        catch(Exception e)
        {
            ModdingToolkit.Utils.Logging.PrintError($"Mechtrauma.Utils::GetComponentsByName() | Could not find any type by the name of {name}. Details: {e.Message}");
        }
    }

    private static List<T> _GetComponentsByNameInternal<T>(Item item) where T : ItemComponent
    {
        List<T> l = new();


        return l;
    }
}