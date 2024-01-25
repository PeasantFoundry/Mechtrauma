namespace Mechtrauma.TransferSystems;

public class VaporContainer : IFluidContainer
{
    public Dictionary<string, IFluidData> ContainedFluids { get; protected set; } = new();

    public float AvgDensity { get; protected set; }
    public float Pressure { get; protected set; }
    public float Temperature { get; protected set; }
    public float Velocity { get; protected set; }
    public float Volume { get; protected set; }
    public float ContainerVolume { get; protected set; }
    public float FluidMass { get; protected set; }
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

    public void UpdateForContainerVolume(float newVolume)
    {
        throw new NotImplementedException();
    }

    public void UpdateForMass(float newMass)
    {
        throw new NotImplementedException();
    }

    public bool CanTakeFluid()
    {
        throw new NotImplementedException();
    }

    public T2 TakeFluidProportional<T, T2>(float volume) where T : IFluidData, new() where T2 : IList<T>
    {
        throw new NotImplementedException();
    }

    public T2 TakeFluidBottom<T, T2>(float volume) where T : IFluidData, new() where T2 : IList<T>
    {
        throw new NotImplementedException();
    }

    public T2 TakeFluidTop<T, T2>(float volume) where T : IFluidData, new() where T2 : IList<T>
    {
        throw new NotImplementedException();
    }

    public bool TryTakeFluidSpecific<T>(string name, float volume, out T fluidData) where T : IFluidData, new()
    {
        throw new NotImplementedException();
    }

    public bool CanPutFluids<T, T2>(in T2 fluids) where T : IFluidData, new() where T2 : IList<T>
    {
        throw new NotImplementedException();
    }

    public bool PutFluids<T, T2>(in T2 fluids) where T : IFluidData, new() where T2 : IList<T>
    {
        throw new NotImplementedException();
    }

    public float GetMaxFreeVolume<T>(in T fluidData) where T : IFluidData, new()
    {
        throw new NotImplementedException();
    }

    public float GetMaxFreeVolume<T, T2>(in T2 fluidData) where T : IFluidData, new() where T2 : IList<T>
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