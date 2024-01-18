namespace Mechtrauma.TransferSystems;

public interface IVaporData : IFluidData
{
    public static readonly string SymbolConnInput = "vapor_input";
    public static readonly string SymbolConnOutput = "vapor_output";
    
    public float CondensateRatio { get; }
}