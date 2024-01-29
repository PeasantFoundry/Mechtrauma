namespace Mechtrauma.TransferSystems;

public struct VaporData : IVaporData
{
    public VaporData(string identifier, string friendlyName)
    {
        Identifier = identifier;
        FriendlyName = friendlyName;

        if (FluidDatabase.Instance.GetFluidProperties(identifier, FluidProperties.PhaseType.Vapor) is { } properties)
        {
            Density = properties.DensitySTP;
        }
        else
        {
            Density = 0f;
        }

        Pressure = 100000f; // 1 Bar / 10 kPa / STP
        Temperature = 273.15f; // kelvin / 0°C / 32°F / STP
        Mass = 0f;
        Volume = 0f;
        Velocity = 0f;
        CondensateRatio = 0f;
    }

    public string Identifier { get; }
    public string FriendlyName { get; }
    public float CondensateRatio { get; }
    public float Density { get; }
    public float Pressure { get; }
    public float Temperature { get; }
    public float Velocity { get; }
    public float Volume { get; }
    public float Mass { get; }
    public FluidProperties.PhaseType Phase { get; } = FluidProperties.PhaseType.Vapor;

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