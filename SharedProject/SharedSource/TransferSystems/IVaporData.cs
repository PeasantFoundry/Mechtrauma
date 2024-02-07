namespace Mechtrauma.TransferSystems;

public interface IVaporData : IFluidData
{
    public float CondensateRatio { get; }
}