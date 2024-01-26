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
        newVolume = Math.Clamp(newVolume, 0f, ContainerVolume);
        if (newVolume < 0.01f)
        {
            Volume = 0f;
            ContainedFluids.Clear();    // empty container
            FluidMass = 0f;
            AvgDensity = 0f;
            return;
        }
        
        var ratio = newVolume / Volume;
        Volume = newVolume;
        FluidMass *= ratio;
        
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
        UpdateForVolume(newMass / FluidMass / AvgDensity);
    }

    public bool CanTakeFluid()
    {
        return ContainedFluids.Any() & Volume > float.Epsilon;
    }

    public T2 TakeFluidProportional<T, T2>(float volume) where T : struct, IFluidData where T2 : IList<T>, new()
    {
        T2 fluidData = new T2();
        float volumeRatio = Math.Clamp(volume, 0f, Volume) / Volume;
        foreach (KeyValuePair<string,IFluidData> data in ContainedFluids)
        {
            if (data.Value is not T data2) continue;
            data2.UpdateForVolume(data2.Volume * volumeRatio);
            fluidData.Add(data2);
        }

        return fluidData;
    }

    public T2 TakeFluidBottom<T, T2>(float volume) where T : struct, IFluidData where T2 : IList<T>, new()
    {
        throw new NotImplementedException();
    }

    public T2 TakeFluidTop<T, T2>(float volume) where T : struct, IFluidData where T2 : IList<T>, new()
    {
        throw new NotImplementedException();
    }

    public bool TryTakeFluidSpecific<T>(string name, float volume, out T fluidData) where T : struct, IFluidData
    {
        throw new NotImplementedException();
    }

    public bool CanPutFluids<T, T2>(in T2 fluids) where T : struct, IFluidData where T2 : IList<T>, new()
    {
        throw new NotImplementedException();
    }

    public bool PutFluids<T, T2>(in T2 fluids) where T : struct, IFluidData where T2 : IList<T>, new()
    {
        throw new NotImplementedException();
    }

    public float GetMaxFreeVolume<T>(in T fluidData) where T : struct, IFluidData
    {
        throw new NotImplementedException();
    }

    public float GetMaxFreeVolume<T, T2>(in T2 fluidData) where T : struct, IFluidData where T2 : IList<T>, new()
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