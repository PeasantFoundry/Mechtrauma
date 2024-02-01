namespace Mechtrauma.TransferSystems;

public interface IVaporContainer<T> : IFluidContainer<T> where T : struct, IVaporData
{
    public float MaxContainerVolume { get; }
}