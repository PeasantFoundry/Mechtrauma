namespace Mechtrauma.TransferSystems;

public class FluidProperties
{
    /// <summary>
    /// The identifier for the fluid (master name, phase agnostic ID).
    /// </summary>
    public string Identifier { get; init; }
    /// <summary>
    /// Identifier name in context of it's phase (ie. water, steam)
    /// </summary>
    public string PhaseIdentifier { get; init; }
    /// <summary>
    /// What phase is this fluid in for the data in the entry.
    /// </summary>
    public PhaseType Phase { get; init; }
    /// <summary>
    /// Heat needed to raise the temperature of 1kg by 1°K (Joules).
    /// </summary>
    public float SensibleHeat { get; init; }
    /// <summary>
    /// Specific heat, amount of heat needed to increase temperature by 1°C/K at constant pressure (Joules). 
    /// </summary>
    public float SpecificHeatPress { get; init; }
    /// <summary>
    /// Specific heat, amount of heat needed to increase temperature by 1°C/K at constant volume (Joules).
    /// </summary>
    public float SpecificHeatVol { get; init; }
    /// <summary>
    /// Heat energy required to change 1kg of fluid from liquid to vapor at Standard SI (Joules). 
    /// </summary>
    public float LatentHeat { get; init; }
    /// <summary>
    /// This is the ideal gas constant.
    /// </summary>
    public float FluidExpansionFactor { get; init; }
    /// <summary>
    /// How much velocity is added from a fluid based on pressure differential.
    /// </summary>
    public float AccelerationRatio { get; init; }
    /// <summary>
    /// Density at IUPAC STP.
    /// </summary>
    public float DensitySTP { get; init; }

    public enum PhaseType
    {
        Liquid, Gas
    }

    // todo: add vapor and liquid tables support in subtypes
}