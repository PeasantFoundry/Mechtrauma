namespace Mechtrauma.TransferSystems;

public class VaporContainer : IVaporContainer<VaporData>
{
    public Dictionary<string, VaporData> ContainedFluids { get; }
    public HashSet<string> FluidRestrictions { get; }
    public float AvgDensity { get; }
    public float Pressure { get; }
    public float Temperature { get; }
    public float Velocity { get; }
    public float Volume { get; }
    public float ContainerVolume { get; }
    public float FluidMass { get; }
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

    public T2 TakeFluidProportional<T2>(float volume) where T2 : IList<VaporData>, new()
    {
        throw new NotImplementedException();
    }

    public T2 TakeFluidBottom<T2>(float volume) where T2 : IList<VaporData>, new()
    {
        throw new NotImplementedException();
    }

    public T2 TakeFluidTop<T2>(float volume) where T2 : IList<VaporData>, new()
    {
        throw new NotImplementedException();
    }

    public bool TryTakeFluidSpecific(string name, float volume, out VaporData fluidData)
    {
        throw new NotImplementedException();
    }

    public bool CanPutFluids<T2>(in T2 fluids) where T2 : IList<VaporData>, new()
    {
        throw new NotImplementedException();
    }

    public bool PutFluids<T2>(in T2 fluids, bool overrideChecks = false) where T2 : IList<VaporData>, new()
    {
        throw new NotImplementedException();
    }

    public float GetMaxFreeVolume(in VaporData fluidData)
    {
        throw new NotImplementedException();
    }

    public float GetMaxFreeVolume<T2>(in T2 fluidData) where T2 : IList<VaporData>, new()
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