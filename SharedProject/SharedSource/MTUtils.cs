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

    /// <summary>
    /// Gets the Damage Per Second conversion value from percentage given the max condition of an item.
    /// </summary>
    /// <param name="unadjustedValue"></param>
    /// <param name="maxCondition"></param>
    /// <returns></returns>
    public static float GetSettingDPS(float unadjustedValue, float maxCondition = 100f) => maxCondition / unadjustedValue / 60f;
    
    /// <summary>
    /// 
    /// </summary>
    /// <param name="unadjustedValue"></param>
    /// <param name="updateTime"></param>
    /// <returns></returns>
    private static float GetServiceLifeDelta(float unadjustedValue, float updateTime = 2f) => unadjustedValue * 60f / updateTime;
}