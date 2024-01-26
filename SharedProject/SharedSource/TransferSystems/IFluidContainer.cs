namespace Mechtrauma.TransferSystems;

public interface IFluidContainer
{
    public Dictionary<string, IFluidData> ContainedFluids { get; }
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
    public T2 TakeFluidProportional<T,T2>(float volume) where T : struct, IFluidData where T2 : IList<T>, new();
    public T2 TakeFluidBottom<T,T2>(float volume) where T : struct, IFluidData where T2 : IList<T>, new();
    public T2 TakeFluidTop<T,T2>(float volume) where T : struct, IFluidData where T2 : IList<T>, new();
    public bool TryTakeFluidSpecific<T>(string name, float volume, out T fluidData) where T : struct, IFluidData;    
    
    public bool CanPutFluids<T,T2>(in T2 fluids) where T : struct, IFluidData where T2 : IList<T>, new();
    public bool PutFluids<T,T2>(in T2 fluids) where T : struct, IFluidData where T2 : IList<T>, new();
    public float GetMaxFreeVolume<T>(in T fluidData) where T : struct, IFluidData;
    /// <summary>
    /// Given a sample list (no volume), returns the available volume for storing any combination of the fluids in the list
    /// at their supplied values (pressure, temperature, etc.).
    /// </summary>
    /// <param name="fluidData"></param>
    /// <typeparam name="T"></typeparam>
    /// <typeparam name="T2"></typeparam>
    /// <returns></returns>
    public float GetMaxFreeVolume<T,T2>(in T2 fluidData) where T : struct, IFluidData where T2 : IList<T>, new();

    public float GetApertureSizeForConnection(string connName);
    public void SetApertureSizeForConnection(string connName, float value);
}