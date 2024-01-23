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
    public IReadOnlyList<T> TakeFluidProportional<T>(float volume) where T : IFluidData, new();
    public IReadOnlyList<T> TakeFluidBottom<T>(float volume) where T : IFluidData, new();
    public IReadOnlyList<T> TakeFluidTop<T>(float volume) where T : IFluidData, new();
    public bool TryTakeFluidSpecific<T>(string name, float volume, out T fluidData) where T : IFluidData, new();    
    
    public bool CanPutFluids<T>(IReadOnlyList<T> fluids) where T : IFluidData, new();
    public bool PutFluids<T>(IReadOnlyList<T> fluids) where T : IFluidData, new();
    public float GetMaxFreeVolume<T>(in T fluidData) where T : IFluidData, new();
    /// <summary>
    /// Given a sample list (no volume), returns the available volume for storing any combination of the fluids in the list
    /// at their supplied values (pressure, temperature, etc.).
    /// </summary>
    /// <param name="fluidData"></param>
    /// <typeparam name="T"></typeparam>
    /// <typeparam name="T2"></typeparam>
    /// <returns></returns>
    public float GetMaxFreeVolume<T,T2>(T2 fluidData) where T : IFluidData, new() where T2 : IEnumerable<T>;

    public float GetApertureSizeForConnection(string connName);
    public void SetApertureSizeForConnection(string connName, float value);
}