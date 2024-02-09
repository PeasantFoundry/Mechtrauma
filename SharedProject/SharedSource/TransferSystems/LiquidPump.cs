 using Barotrauma;
using Barotrauma.Items.Components;

namespace Mechtrauma.TransferSystems;

/// <summary>
/// Modeled based on a positive displacement pump.
/// </summary>
public class LiquidPump : Powered, IFluidDevice<LiquidContainer, LiquidData>
{
    #region VARS

    public static readonly string Event_PreUpdatePumping = "Mechtrauma.TransferSystems.LiquidPump::UpdatePumping-Pre";
    public static readonly string Event_PostUpdatePumping = "Mechtrauma.TransferSystems.LiquidPump::UpdatePumping-Post";

    private readonly LiquidContainer _inletContainer;
    private readonly LiquidContainer _outletContainer;
    private float _previousOutletContainerVolume = 0f;
    private readonly ImmutableList<LiquidContainer> _containers;

    private int _ticksUntilUpdate = 0;
    
    private float _maxDeltaPressure;
    [Editable, Serialize(250, IsPropertySaveable.Yes, "Max output pressure of the pump, compared to it's input, in KiloPascals.")]
    public float MaxDeltaPressure
    {
        get => _maxDeltaPressure;
        set => _maxDeltaPressure = Math.Max(1f, value);
    }

    private float _targetFlowRate;
    [Editable, Serialize(35, IsPropertySaveable.Yes, "Target flow rate of the pump in Liters/second.")]
    public float TargetFlowRate
    {
        get => _targetFlowRate;
        set => _targetFlowRate = Math.Max(0.01f, value);
    }

    private float _maxApertureSize;

    [Editable, Serialize(100f, IsPropertySaveable.Yes, "Max Aperture Size of the pump.")]
    public float MaxApertureSize
    {
        get => _maxApertureSize;
        set => _maxApertureSize = Math.Max(1f, value);
    }

    private float _maxPowerConsumption;
    [Editable, Serialize(20, IsPropertySaveable.Yes, "Max power consumption allowed by the pump in kW.")]
    public float MaxPowerConsumption
    {
        get => _maxPowerConsumption;
        set => _maxPowerConsumption = Math.Max(0f, value);
    }

    private float _minVelocityOut;
    [Editable, Serialize(1f, IsPropertySaveable.Yes, "Minimum output velocity.")]
    public float MinVelocityOut
    {
        get => _minVelocityOut;
        set => _minVelocityOut = Math.Max(0f, value);
    }

    
    #endregion

    
    public LiquidPump(Item item, ContentXElement element) : base(item, element)
    {
        _inletContainer = new();
        _outletContainer = new();
        _containers = ImmutableList.Create(_inletContainer, _outletContainer);
    }


    public T3 GetFluidContainers<T3>() where T3 : class, IList<LiquidContainer>, new()
    {
        var l = new T3();
        foreach (var container in _containers)
        {
            l.Add(container);
        }
        return l;
    }

    public T3 GetFluidContainersByGroup<T3>(string groupName) where T3 : class, IList<LiquidContainer>, new()
    {
        var l = new T3();
        if (groupName == LiquidData.SymbolConnInput)
            l.Add(_inletContainer);
        if (groupName == LiquidData.SymbolConnOutput)
            l.Add(_outletContainer);
        return l;
    }

    public LiquidContainer? GetPrefContainerByGroup(string groupName)
    {
        if (groupName == LiquidData.SymbolConnInput)
            return _inletContainer;
        if (groupName == LiquidData.SymbolConnOutput)
            return _outletContainer;
        return null;
    }

    public FluidProperties.PhaseType OutputPhaseType { get; init; } = FluidProperties.PhaseType.Liquid;
    public FluidProperties.PhaseType InputPhaseType { get; init; } = FluidProperties.PhaseType.Liquid;

    public override void Update(float deltaTime, Camera cam)
    {
        base.Update(deltaTime, cam);
        _ticksUntilUpdate--;
        if (_ticksUntilUpdate < 1)
        {
            _ticksUntilUpdate = FluidSystemData.WaitTicksBetweenUpdates;
            UpdatePumping();
        }
    }

    protected virtual void UpdatePumping()
    {
        GameMain.LuaCs.Hook.Call(Event_PreUpdatePumping, this);
        
        // todo: logic
        throw new NotImplementedException();
        
        // Compute difference in volume from last update, vDiff
        // if vDiff > 0 then
            // Calculate new Velocity based on movement
        // else
            // Assume minimum velocity
        // Calculate required pressure and aperture to hit target
        

        GameMain.LuaCs.Hook.Call(Event_PostUpdatePumping, this);
    }
}