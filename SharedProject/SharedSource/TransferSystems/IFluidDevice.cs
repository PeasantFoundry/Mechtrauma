namespace Mechtrauma.TransferSystems;

public interface IFluidDevice
{
    public IReadOnlyList<T> GetFluidContainers<T>() where T : class, IFluidContainer, new();
    public IReadOnlyList<T> GetFluidContainersByGroup<T>(string groupName) where T : class, IFluidContainer, new();
    public T? GetPrefContainerByGroup<T>(string groupName) where T : class, IFluidContainer, new();

    public static readonly int TickRate = 10;
    public static readonly int WaitTicksBetweenUpdates = 60 / TickRate;
    public static readonly float FixedDeltaTime = 1000f / (float)TickRate;
}