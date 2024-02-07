namespace Mechtrauma.TransferSystems;

public interface IFluidDevice<T, T2> where T : class, IFluidContainer<T2>, new() where T2 : struct, IFluidData
{
    public T3 GetFluidContainers<T3>() where T3 : class, IList<T>, new();
    public T3 GetFluidContainersByGroup<T3>(string groupName) where T3 : class, IList<T>, new();
    public T? GetPrefContainerByGroup(string groupName);
    
    public FluidProperties.PhaseType OutputPhaseType { get; }
    public FluidProperties.PhaseType InputPhaseType { get; }
}

public static class FluidSystemData
{
    public static readonly int TickRate = 10;
    public static readonly int WaitTicksBetweenUpdates = 60 / TickRate;
    public static readonly float FixedDeltaTime = 1000f / (float)TickRate;
}

