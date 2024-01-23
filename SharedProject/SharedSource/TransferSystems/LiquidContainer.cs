namespace Mechtrauma.TransferSystems;

public class LiquidContainer : IFluidContainer
{
    public ref readonly Dictionary<string, IFluidData> ContainedFluids => throw new NotImplementedException();

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