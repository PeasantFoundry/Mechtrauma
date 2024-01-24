namespace Mechtrauma.TransferSystems;

public class LiquidContainer : IFluidContainer 
{
    public Dictionary<string, IFluidData> ContainedFluids { get; protected set; }

    public float AvgDensity { get; protected set; }
    public float Pressure { get; protected set; }
    public float Temperature { get; protected set; }
    public float Velocity { get; protected set; }
    public float Volume { get; protected set; }
    public float ContainerVolume { get; protected set; }
    public float FluidMass { get; protected set; }
    
    public void UpdateForPressure(float newPressure)
    {
        Pressure = Math.Max(0f, newPressure);
        foreach (var fluid in ContainedFluids)
        {
            fluid.Value.UpdateForPressure(Pressure);
        }
    }

    public void UpdateForTemperature(float newTemperature)
    {
        Temperature = Math.Max(0f, newTemperature);
        foreach (var fluid in ContainedFluids)
        {
            fluid.Value.UpdateForTemperature(Temperature);
        }
    }

    public void UpdateForVelocity(float newVelocity)
    {
        Velocity = Math.Max(0f, newVelocity);
        foreach (var fluid in ContainedFluids)
        {
            fluid.Value.UpdateForVelocity(Velocity);
        }
    }

    public void UpdateForVolume(float newVolume)
    {
        newVolume = Math.Max(0f, newVolume);
        var ratio = newVolume / Volume;
        Volume = newVolume;
        if (newVolume < 0.001f)
        {
            Volume = 0f;
            ContainedFluids.Clear();    // empty container
            return;
        }
        foreach (var fluid in ContainedFluids)
        {
            fluid.Value.UpdateForVolume(fluid.Value.Volume * ratio);
        }
    }

    public void UpdateForContainerVolume(float newVolume)
    {
        ContainerVolume = Math.Max(0f, newVolume);
        if (ContainerVolume < Volume)
        {
            UpdateForVolume(newVolume);
        }
    }

    public void UpdateForMass(float newMass)
    {
        throw new NotImplementedException();
    }

    public bool CanTakeFluid()
    {
        return ContainedFluids.Any() & Volume > float.Epsilon;
    }

    public IReadOnlyList<T> TakeFluidProportional<T>(float volume) where T : IFluidData, new()
    {
        throw new NotImplementedException();
    }

    public IReadOnlyList<T> TakeFluidBottom<T>(float volume) where T : IFluidData, new()
    {
        throw new NotImplementedException();
    }

    public IReadOnlyList<T> TakeFluidTop<T>(float volume) where T : IFluidData, new()
    {
        throw new NotImplementedException();
    }

    public bool TryTakeFluidSpecific<T>(string name, float volume, out T fluidData) where T : IFluidData, new()
    {
        throw new NotImplementedException();
    }

    public bool CanPutFluids<T>(IReadOnlyList<T> fluids) where T : IFluidData, new()
    {
        throw new NotImplementedException();
    }

    public bool PutFluids<T>(IReadOnlyList<T> fluids) where T : IFluidData, new()
    {
        throw new NotImplementedException();
    }

    public float GetMaxFreeVolume<T>(in T fluidData) where T : IFluidData, new()
    {
        throw new NotImplementedException();
    }

    public float GetMaxFreeVolume<T,T2>(T2 fluidData) where T : IFluidData, new() where T2 : IEnumerable<T>
    {
        throw new NotImplementedException();
    }

    public float GetApertureSizeForConnection(string connName)
    {
        throw new NotImplementedException();
    }

    public void SetApertureSizeForConnection(string connName, float value)
    {
        throw new NotImplementedException();
    }
}