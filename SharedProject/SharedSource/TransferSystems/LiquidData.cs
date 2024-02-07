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
        if (Volume < 0.001f)
            return;
        if (newDensity < float.Epsilon)
            return;
        Density = newDensity;
        Mass = Density * Volume;
    }

    public void UpdateForPressure(float newPressure)
    {
        Pressure = Math.Max(0f, newPressure);
    }

    public void UpdateForTemperature(float newTemperature)
    {
        Temperature = Math.Max(0f, newTemperature);
    }

    public void UpdateForVelocity(float newVelocity)
    {
        Velocity = Math.Max(0f, newVelocity);
    }

    public void UpdateForVolume(float newVolume)
    {
        if (newVolume < 0.001f)
        {
            Volume = 0f;
            Mass = 0f;
            Pressure = 0f;
            Velocity = 0f;
            Temperature = 0f;
            return;
        }

        if (Volume < 0.001f)
            return;

        Volume = Math.Max(0f, newVolume);
        Mass = Density * Volume;
    }

    public void UpdateForMass(float newMass)
    {
        UpdateForVolume(newMass / Mass * Volume);
    }

    public T Clone<T>() where T : struct, IFluidData
    {
        if (typeof(T) != typeof(LiquidData))
            return new T();
        return (T)(ILiquidData)this;
    }

    public static string SymbolConnInput => "liquid_input";
    public static string SymbolConnOutput => "liquid_output";
}