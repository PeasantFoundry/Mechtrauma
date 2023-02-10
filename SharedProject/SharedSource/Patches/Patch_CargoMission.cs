using Barotrauma;
using Barotrauma.Items.Components;
using HarmonyLib;
using ModdingToolkit.Patches;

namespace Mechtrauma.Patches;

public class Patch_CargoMission : IPatchable
{
    public static readonly string CARGO_FILTER_TAG = "specialcargo";

    public List<PatchManager.PatchData> GetPatches()
    {
        return new List<PatchManager.PatchData>()
        {
            new (AccessTools.DeclaredMethod(typeof(Barotrauma.CargoMission), nameof(Barotrauma.CargoMission.DetermineCargo)),
                new HarmonyMethod(AccessTools.DeclaredMethod(typeof(Patch_CargoMission), nameof(Prefix_DetermineCargo))),
                null)
        };
    }

    // Seems silly but serves as a wrapper.
    public static bool Prefix_DetermineCargo(Barotrauma.CargoMission __instance)
    {
        DetermineCargo(__instance);
        return false;
    }

    private static void DetermineCargo(Barotrauma.CargoMission instance)
    {
        if (instance.currentSub == null || instance.itemConfig == null)
        {
            instance.calculatedReward = instance.Prefab.Reward;
            return;
        }

        instance.itemsToSpawn.Clear();

        instance.maxItemCount = 0;
        foreach (var subElement in instance.itemConfig.Elements())
        {
            int maxCount = subElement.GetAttributeInt("maxcount", 10);
            instance.maxItemCount += maxCount;
        }

        var pendingSubInfo = GameMain.GameSession?.Campaign?.PendingSubmarineSwitch;
        if (pendingSubInfo != null && pendingSubInfo != instance.currentSub.Info)
        {
            //if we've got a submarine switch pending, calculate the amount of cargo based on it's cargo capacity
            instance.maxItemCount = Math.Min(instance.maxItemCount, pendingSubInfo.CargoCapacity);
            instance.previouslySelectedMissions.Clear();
            if (GameMain.GameSession?.StartLocation?.SelectedMissions != null)
            {
                bool isPriorMission = true;
                foreach (Mission mission in GameMain.GameSession.StartLocation.SelectedMissions)
                {
                    if (!(mission is CargoMission otherMission)) { continue; }
                    if (mission == instance) { isPriorMission = false; }
                    instance.previouslySelectedMissions.Add(otherMission);
                    if (!isPriorMission) { continue; }
                    instance.maxItemCount -= otherMission.itemsToSpawn.Count;
                }
            }
            for (int i = 0; i < instance.maxItemCount; i++)
            {
                foreach (var subElement in instance.itemConfig.Elements())
                {
                    int maxCount = subElement.GetAttributeInt("maxcount", 10);
                    if (instance.itemsToSpawn.Count(it => it.element == subElement) >= maxCount) { continue; }
                    ItemPrefab itemPrefab = instance.FindItemPrefab(subElement);
                    while (instance.itemsToSpawn.Count < instance.maxItemCount)
                    {
                        instance.itemsToSpawn.Add((subElement, null));
                        if (instance.itemsToSpawn.Count(it => it.element == subElement) >= maxCount) { break; }
                    }
                }
            }
            instance.maxItemCount = Math.Max(0, instance.maxItemCount);
            instance.nextRoundSubInfo = pendingSubInfo;
        }
        else
        {
            List<(ItemContainer container, int freeSlots)> containers = instance.currentSub.GetCargoContainers();
            if (instance.Prefab.Tags.Any(t => t.ToLowerInvariant().Trim().Contains(CARGO_FILTER_TAG)))
            {
                containers = containers.Where(c =>
                {
                    foreach (string tag in instance.Prefab.Tags)
                    {
                        if (!c.container.Item.HasTag(tag))
                            return false;
                    }
                    return true;
                }).ToList();
            }
            containers.Sort((c1, c2) => { return c2.container.Capacity.CompareTo(c1.container.Capacity); });
            
            instance.previouslySelectedMissions.Clear();
            if (GameMain.GameSession?.StartLocation?.SelectedMissions != null)
            {
                bool isPriorMission = true;
                foreach (Mission mission in GameMain.GameSession.StartLocation.SelectedMissions)
                {
                    if (!(mission is CargoMission otherMission)) { continue; }
                    if (mission == instance) { isPriorMission = false; }
                    instance.previouslySelectedMissions.Add(otherMission);                    
                    if (!isPriorMission) { continue; }
                    foreach (var (element, container) in otherMission.itemsToSpawn)
                    {
                        for (int i = 0; i < containers.Count; i++)
                        {
                            if (containers[i].container == container)
                            {
                                containers[i] = (containers[i].container, containers[i].freeSlots - 1);
                                break;
                            }
                        }
                    }
                }
            }

            for (int i = 0; i < containers.Count; i++)
            {
                foreach (var subElement in instance.itemConfig.Elements())
                {
                    int maxCount = subElement.GetAttributeInt("maxcount", 10);
                    if (instance.itemsToSpawn.Count(it => it.element == subElement) >= maxCount) { continue; }
                    ItemPrefab itemPrefab = instance.FindItemPrefab(subElement);
                    while (containers[i].freeSlots > 0 && containers[i].container.Inventory.CanBePut(itemPrefab))
                    {
                        containers[i] = (containers[i].container, containers[i].freeSlots - 1);
                        instance.itemsToSpawn.Add((subElement, containers[i].container));
                        if (instance.itemsToSpawn.Count(it => it.element == subElement) >= maxCount) { break; }
                    }
                }
            }
        }

        if (!instance.itemsToSpawn.Any())
        {
            instance.itemsToSpawn.Add((instance.itemConfig.Elements().First(), null));
        }

        instance.calculatedReward = 0;
        foreach (var (element, container) in instance.itemsToSpawn)
        {
            int price = element.GetAttributeInt("reward", instance.Prefab.Reward / instance.itemsToSpawn.Count);
            if (instance.rewardPerCrate.HasValue)
            {
                if (price != instance.rewardPerCrate.Value) { instance.rewardPerCrate = -1; }
            }
            else
            {
                instance.rewardPerCrate = price;
            }
            instance.calculatedReward += price;
        }
        if (instance.rewardPerCrate.HasValue && instance.rewardPerCrate < 0) { instance.rewardPerCrate = null; }

        string rewardText = $"‖color:gui.orange‖{string.Format(System.Globalization.CultureInfo.InvariantCulture, "{0:N0}", instance.GetReward(instance.currentSub))}‖end‖";
        if (instance.descriptionWithoutReward != null) { instance.description = instance.descriptionWithoutReward.Replace("[reward]", rewardText); }
    }
}