namespace Mechtrauma.TransferSystems;

public struct VaporData : IVaporData
{
    public string Identifier { get; }
    public string FriendlyName { get; }
    public float CondensateRatio { get; }
    public float Density { get; }
    public float Pressure { get; }
    public float Temperature { get; }
    public float Velocity { get; }
    public float Volume { get; }
    public float Mass { get; }

    public void UpdateForDensity(float newDensity)
    {
        throw new NotImplementedException();
    }

    public void UpdateForPressure(float newPressure)
    {
        throw new NotImplementedException();
    }

    public void UpdateForTemperature(float newTemperature)
    {
        throw new NotImplementedException();
    }

    public void UpdateForVelocity(float newVelocity)
    {
        throw new NotImplementedException();
    }

    public void UpdateForVolume(float newVolume)
    {
        throw new NotImplementedException();
    }

    public void UpdateForMass(float newMass)
    {
        throw new NotImplementedException();
    }

    public T Clone<T>() where T : struct, IFluidData
    {
        throw new NotImplementedException();
    }
}