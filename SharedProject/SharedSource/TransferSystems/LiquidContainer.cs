using Barotrauma;

namespace Mechtrauma.TransferSystems;

public class LiquidContainer : IFluidContainer
{
    public Dictionary<string, IFluidData> ContainedFluids => _containedFluids.ToDictionary(
        kvp => kvp.Key,
        kvp => (IFluidData)kvp.Value);
    private readonly SortedList<string, LiquidData> _containedFluids = new();
    private List<string> _fluidsByDensity = new();
    public IReadOnlyList<string> FluidsByDensity => _fluidsByDensity;
    public HashSet<string> FluidRestrictions { get; } = new();
    public float AvgDensity { get; protected set; }
    public float Pressure { get; protected set; }
    public float Temperature { get; protected set; }
    public float Velocity { get; protected set; }
    public float Volume { get; protected set; }
    public float ContainerVolume { get; protected set; }
    public float FluidMass { get; protected set; }

    private readonly Dictionary<string, float> _apertureSizes = new();

    public event Func<IList<LiquidData>, bool>? OnCanPutFluids;

    public void UpdateForPressure(float newPressure)
    {
        Pressure = Math.Max(0f, newPressure);
        for (int i = 0; i < _containedFluids.Count; i++)
        {
            var fluid = _containedFluids.Values[i];
            fluid.UpdateForPressure(Pressure);
            _containedFluids.Values[i] = fluid;
        }
    }

    public void UpdateForTemperature(float newTemperature)
    {
        Temperature = Math.Max(0f, newTemperature);
        for (int i = 0; i < _containedFluids.Count; i++)
        {
            var fluid = _containedFluids.Values[i];
            fluid.UpdateForTemperature(Temperature);
            _containedFluids.Values[i] = fluid;
        }
    }

    public void UpdateForVelocity(float newVelocity)
    {
        Velocity = Math.Max(0f, newVelocity);
        for (int i = 0; i < _containedFluids.Count; i++)
        {
            var fluid = _containedFluids.Values[i];
            fluid.UpdateForVelocity(Velocity);
            _containedFluids.Values[i] = fluid;
        }
    }

    public void UpdateForVolume(float newVolume)
    {
        newVolume = Math.Clamp(newVolume, 0f, ContainerVolume);
        if (newVolume < 0.01f)
        {
            ContainedFluids.Clear();    // empty container
            Volume = 0f;
            FluidMass = 0f;
            AvgDensity = 0f;
            Pressure = 0f;
            Temperature = 0f;
            Velocity = 0f;   
            return;
        }
        
        var ratio = newVolume / Volume;
        Volume = newVolume;
        FluidMass *= ratio;
        
        for (int i = 0; i < _containedFluids.Count; i++)
        {
            var fluid = _containedFluids.Values[i];
            fluid.UpdateForVolume(Volume);
            _containedFluids.Values[i] = fluid;
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
        return _containedFluids.Any() & Volume > float.Epsilon;
    }

    public T2 TakeFluidProportional<T, T2>(float volume) where T : struct, IFluidData where T2 : IList<T>, new()
    {
        T2 fluidData = new T2();
        float volumeRatio = Math.Clamp(volume, 0f, Volume) / Volume;
        foreach (var data in _containedFluids)
        {
            if (data.Value is not T data2) continue; // shallow copy
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
        if (!_containedFluids.ContainsKey(name) || typeof(T) != typeof(LiquidData))
        {
            fluidData = new T();
            return false;
        }

        var fluid = _containedFluids[name];
        volume = Math.Min(fluid.Volume, volume);
        fluidData = (T)(ILiquidData)fluid;
        // todo: fix this random ass code you were too tired to finish
        throw new NotImplementedException();
    }

    public bool CanPutFluids<T, T2>(in T2 fluids) where T : struct, IFluidData where T2 : IList<T>, new()
    {
        if (typeof(T) != typeof(LiquidData))
            return false;
        float sumVolume=0f;
        for (int i = 0; i < fluids.Count; i++)
        {
            sumVolume += fluids[i].Volume;
            if (FluidRestrictions.Contains(fluids[i].Identifier))
                return false;
            if (fluids[i].Phase != FluidProperties.PhaseType.Liquid)
                return false;
        }

        if (ContainerVolume < sumVolume + Volume)
            return false;

        if (OnCanPutFluids is not null)
        {
            foreach (Delegate del in OnCanPutFluids.GetInvocationList())
            {
                try
                {
                    if (del.DynamicInvoke() is false)
                        return false;
                }
                catch
                {
                    ModUtils.Logging.PrintError($"{nameof(LiquidContainer)}::{nameof(CanPutFluids)}() | Delegate error. Name: {del.Method.Name}");
                    continue;
                }
            }
        }

        return true;
    }

    public bool PutFluids<T, T2>(in T2 fluids, bool overrideChecks = false) where T : struct, IFluidData where T2 : IList<T>, new()
    {
        if (!overrideChecks && !CanPutFluids<T, T2>(fluids))
            return false;
        
        // even if safety checks are skipped, this needs to always be the case.
        if (typeof(T) != typeof(LiquidData))
            return false;

        List<LiquidData> fluidsData = fluids.Cast<LiquidData>().ToList();
        foreach (LiquidData data in fluidsData)
        {
            if (data.Volume < float.Epsilon)
                continue;

            if (!_containedFluids.ContainsKey(data.Identifier))
            {
                _containedFluids[data.Identifier] = data;
            }
            else
            {
                LiquidData orgData = _containedFluids[data.Identifier];
                float newVol = orgData.Volume + data.Volume;
                float orgVolProp = orgData.Volume / newVol;
                float newVolProp = data.Volume / newVol;
                orgData.UpdateForVolume(newVol);
                orgData.UpdateForPressure(Math.Max(orgData.Pressure, data.Pressure));
                orgData.UpdateForDensity(orgData.Density * orgVolProp + data.Density * newVolProp);
                orgData.UpdateForTemperature(orgData.Temperature * orgVolProp + data.Temperature * newVolProp);
                orgData.UpdateForVelocity(orgData.Velocity * orgVolProp + data.Velocity * newVolProp);
                _containedFluids[data.Identifier] = orgData;
            }
            // we update volume here because looping again later to do so causes 
            // a struct copy
            this.Volume += data.Volume; 
        }
        
        UpdateFluidsListNoVol();
        return true;
    }

    public float GetMaxFreeVolume<T>(in T fluidData) where T : struct, IFluidData
    {
        if (typeof(T) != typeof(LiquidData))
            return 0f;
        return ContainerVolume - Volume;
    }

    public float GetMaxFreeVolume<T, T2>(in T2 fluidData) where T : struct, IFluidData where T2 : IList<T>, new()
    {
        if (typeof(T) != typeof(LiquidData))
            return 0f;
        return ContainerVolume - Volume;
    }

    public float GetApertureSizeForConnection(string connName)
    {
        if (_apertureSizes.ContainsKey(connName))
            return _apertureSizes[connName];
        return 0f;
    }

    public void SetApertureSizeForConnection(string connName, float value)
    {
        if (connName != string.Empty && value > 0f)
            _apertureSizes[connName] = value;
    }

    protected void UpdateFluidsListNoVol()
    {
        // remove 0 volume fluids
        var toRemove = _containedFluids
            .Where(kvp => kvp.Value.Volume < float.Epsilon)
            .Select(kvp => kvp.Key);

        foreach (string fluidName in toRemove)
        {
            _containedFluids.Remove(fluidName);
        }

        float tempSum = 0f, pressSum = 0f, totalMass = 0f, velocitySum = 0f;
        foreach (var fluid in _containedFluids)
        {
            tempSum += fluid.Value.Temperature * fluid.Value.Volume;
            pressSum += fluid.Value.Pressure * fluid.Value.Volume;
            totalMass += fluid.Value.Mass;
            velocitySum += fluid.Value.Velocity;
        }

        tempSum /= _containedFluids.Count * this.Volume;
        pressSum /= _containedFluids.Count * this.Volume;
        velocitySum /= _containedFluids.Count;
        this.FluidMass = totalMass;
        this.AvgDensity = totalMass / this.Volume;

        UpdateForPressure(pressSum);
        UpdateForTemperature(tempSum);
        UpdateForVelocity(velocitySum);

        // todo: profile performance
        _fluidsByDensity = _containedFluids
            .OrderBy(c => c.Value.Density)
            .Select(k => k.Key)
            .ToList();
    }
}

