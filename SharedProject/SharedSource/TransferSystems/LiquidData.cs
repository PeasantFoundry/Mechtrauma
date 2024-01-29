namespace Mechtrauma.TransferSystems;

public struct LiquidData : ILiquidData
{
    public string Identifier { get; init; }
    public string FriendlyName { get; init; }
    public float Density { get; private set; }
    public float Pressure { get; private set; }
    public float Temperature { get; private set; }
    public float Velocity { get; private set; }
    public float Volume { get; private set; }
    public float Mass { get; private set; }
    public FluidProperties.PhaseType Phase { get; } = FluidProperties.PhaseType.Liquid;

    public LiquidData(string identifier, string friendlyName)
    {
        Identifier = identifier;
        FriendlyName = friendlyName;

        if (FluidDatabase.Instance.GetFluidProperties(identifier, FluidProperties.PhaseType.Liquid) is { } properties)
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
    }

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
        if (typeof(T) != typeof(LiquidData))
            return new T();
        return (T)(ILiquidData)this;
    }
}