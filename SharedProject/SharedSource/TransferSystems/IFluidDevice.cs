namespace Mechtrauma.TransferSystems;

public interface IFluidDevice
{
    public IReadOnlyList<T> GetFluidContainers<T>() where T : IFluidContainer;
    public IReadOnlyList<T> GetFluidContainersByGroup<T>(string groupName) where T : IFluidContainer;
    public T GetPrefContainerByGroup<T>(string groupName) where T : IFluidContainer;
    
    
}