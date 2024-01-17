namespace Mechtrauma.TransferSystems;

public interface IFluidContainer
{
    public ref readonly Dictionary<string, IFluidData> ContainedFluids { get; }
    public float AvgDensity { get; }
    public float Pressure { get; }
    public float Temperature { get; }
    public float Velocity { get; }
    public float Volume { get; }
    public float ContainerVolume { get; }
    public float FluidMass { get; }

    public void UpdateForPressure(float newPressure);
    public void UpdateForTemperature(float newTemperature);
    public void UpdateForVelocity(float newVelocity);
    public void UpdateForVolume(float newVolume);
    public void UpdateForContainerVolume(float newVolume);
    public void UpdateForMass(float newMass);

    public bool CanTakeFluid();
    public IReadOnlyList<T> TakeFluidProportional<T>(float volume) where T : IFluidData;
    public IReadOnlyList<T> TakeFluidBottom<T>(float volume) where T : IFluidData;
    public IReadOnlyList<T> TakeFluidTop<T>(float volume) where T : IFluidData;
    public bool TryTakeFluidSpecific<T>(string name, float volume, out T fluidData) where T : IFluidData;    
    
    public bool CanPutFluids<T>(IReadOnlyList<T> fluids) where T : IFluidData;
    public bool PutFluids<T>(IReadOnlyList<T> fluids) where T : IFluidData;

    public float GetApertureSizeForConnection(string connName);
}