namespace Mechtrauma.TransferSystems;

public interface IFluidData
{
    public string Identifier { get; }
    public string FriendlyName { get; }
    public float Density { get; }
    public float Pressure { get; }
    public float Temperature { get; }
    public float Velocity { get; }
    public float Volume { get; }
    public float Mass { get; }
    public FluidProperties.PhaseType Phase { get; }

    public void UpdateForDensity(float newDensity);
    public void UpdateForPressure(float newPressure);
    public void UpdateForTemperature(float newTemperature);
    public void UpdateForVelocity(float newVelocity);
    public void UpdateForVolume(float newVolume);
    public void UpdateForMass(float newMass);
    public T Clone<T>() where T : struct, IFluidData;
}