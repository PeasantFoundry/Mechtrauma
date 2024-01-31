namespace Mechtrauma.TransferSystems;

public interface ILiquidContainer<T> : IFluidContainer<T> where T : struct, ILiquidData
{
    
}