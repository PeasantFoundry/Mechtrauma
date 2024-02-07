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
    private readonly ImmutableList<LiquidContainer> _containers;

    private int _ticksUntilUpdate = 0;
    
    private float _maxDeltaPressure;
    [Editable, Serialize(250, IsPropertySaveable.Yes, "Max output pressure of the pump, compared to it's input, in KiloPascals.")]
    public float MaxDeltaPressure
    {
        get => _maxDeltaPressure;
        set
        {
            if (value < 1f)
                value = 1f;
            _maxDeltaPressure = value;
        }
    }

    private float _targetFlowRate;
    [Editable, Serialize(35, IsPropertySaveable.Yes, "Target flow rate of the pump in Liters/second.")]
    public float TargetFlowRate
    {
        get => _targetFlowRate;
        set
        {
            if (value < 0f)
                value = 0f;
            _targetFlowRate = value;
        }
    }
    
    [Editable(0,float.MaxValue), Serialize(20, IsPropertySaveable.Yes, "Max power consumption allowed by the pump in kW.")]
    public float MaxPowerConsumption { get; set; }

    
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
        
        // check how much volume can be moved over to the outlet.

        // calculate outlet pressure adjustment based on fluid level, use 50% as the marker.
        // 0% = inlet pressure.
        // 100% = max pressure. 

        GameMain.LuaCs.Hook.Call(Event_PostUpdatePumping, this);
    }
}