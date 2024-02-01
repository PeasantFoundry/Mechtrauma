using Barotrauma;

namespace Mechtrauma.TransferSystems;

public class LiquidContainer : ILiquidContainer<LiquidData>
{
    public IDictionary<string, LiquidData> ContainedFluids => _containedFluids;
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
            _containedFluids.Clear();    // empty container
            _fluidsByDensity.Clear();
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

    public T2 TakeFluidProportional<T2>(float volume) where T2 : IList<LiquidData>, new()
    {
        if (this.Volume < float.Epsilon)
            return new T2();
        
        T2 fluidData = new T2();
        float volumeRatio = Math.Clamp(volume, 0f, Volume) / Volume;
        foreach (var data in _containedFluids)
        {
            var data2 = data.Value; // struct copy
            data2.UpdateForVolume(data2.Volume * volumeRatio);
            fluidData.Add(data2);
        }
        UpdateFluidsList();

        return fluidData;
    }

    public T2 TakeFluidBottom<T2>(float volume) where T2 : IList<LiquidData>, new()
    {
        T2 outList = new ();
        for (int i = _fluidsByDensity.Count-1; i > -1; i--)
        {
            if (volume < 0.001f)
                break;
            var fluid = _containedFluids[_fluidsByDensity[i]];
            var retFluid = fluid;
            float fluidOrgVol = fluid.Volume;
            float vol = Math.Min(volume, fluidOrgVol);
            
            volume -= vol;
            fluidOrgVol -= vol;
            fluid.UpdateForVolume(vol);
            retFluid.UpdateForVolume(fluidOrgVol);
            
            outList.Add(fluid);
            _containedFluids[_fluidsByDensity[i]] = retFluid;
        }
        
        UpdateFluidsList();
        return outList;
    }

    public T2 TakeFluidTop<T2>(float volume) where T2 : IList<LiquidData>, new()
    {
        T2 outList = new ();
        // ReSharper disable once ForCanBeConvertedToForeach
        for (int i = 0; i < _fluidsByDensity.Count; i++)
        {
            if (volume < 0.001f)
                break;
            var fluid = _containedFluids[_fluidsByDensity[i]];
            var retFluid = fluid;
            float fluidOrgVol = fluid.Volume;
            float vol = Math.Min(volume, fluidOrgVol);
            
            volume -= vol;
            fluidOrgVol -= vol;
            fluid.UpdateForVolume(vol);
            retFluid.UpdateForVolume(fluidOrgVol);
            
            outList.Add(fluid);
            _containedFluids[_fluidsByDensity[i]] = retFluid;
        }
        
        UpdateFluidsList();
        return outList;
    }

    public bool TryTakeFluidSpecific(string name, float volume, out LiquidData fluidData)
    {
        var fluid = _containedFluids[name];
        var outFluid = fluid;   // struct copy
        
        float vol = Math.Min(volume, fluid.Volume);
        outFluid.UpdateForVolume(vol);
        fluid.UpdateForVolume(fluid.Volume - vol);
        _containedFluids[name] = fluid;
        fluidData = outFluid;
        UpdateFluidsList();
        return true;
    }

    public T2 GetFluidSample<T2>() where T2 : IList<LiquidData>, new()
    {
        T2 list = new();
        foreach (var fluid in _containedFluids.Values)
        {
            fluid.UpdateForVolume(1f);
            list.Add(fluid);
        }

        return list;
    }

    public bool CanPutFluids<T2>(in T2 fluids) where T2 : IList<LiquidData>, new()
    {
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

        return true;
    }

    public bool PutFluids<T2>(in T2 fluids, bool overrideChecks = false) where T2 : IList<LiquidData>, new()
    {
        if (!overrideChecks && !CanPutFluids(fluids))
            return false;
        
        foreach (LiquidData data in fluids)
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
        }
        
        UpdateFluidsList();
        return true;
    }

    public float GetMaxFreeVolume(in LiquidData fluidData)
    {
        return ContainerVolume - Volume;
    }

    public float GetMaxFreeVolume<T2>(in T2 fluidData) where T2 : IList<LiquidData>, new()
    {
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

    protected void UpdateFluidsList()
    {
        // remove 0 volume fluids
        var toRemove = _containedFluids
            .Where(kvp => kvp.Value.Volume < float.Epsilon)
            .Select(kvp => kvp.Key);

        foreach (string fluidName in toRemove)
        {
            _containedFluids.Remove(fluidName);
        }

        float tempSum = 0f, pressSum = 0f, totalMass = 0f, velocitySum = 0f, volumeSum = 0f;
        foreach (var fluid in _containedFluids)
        {
            var fluidVal = fluid.Value;
            tempSum += fluidVal.Temperature * fluidVal.Volume;
            pressSum += fluidVal.Pressure * fluidVal.Volume;
            totalMass += fluidVal.Mass;
            velocitySum += fluidVal.Velocity;
            volumeSum += fluidVal.Volume;
        }

        this.Volume = volumeSum;
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

