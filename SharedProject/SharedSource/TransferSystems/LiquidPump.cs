 using Barotrauma;
using Barotrauma.Items.Components;

namespace Mechtrauma.TransferSystems;

/// <summary>
/// Modeled based on a positive displacement pump.
/// </summary>
public class LiquidPump : Powered, IFluidDevice
{
    #region VARS

    public static readonly string Event_PreUpdatePumping = "Mechtrauma.TransferSystems.LiquidPump::UpdatePumping-Pre";
    public static readonly string Event_PostUpdatePumping = "Mechtrauma.TransferSystems.LiquidPump::UpdatePumping-Post";
    
    private readonly LiquidContainer _inletContainer = new();
    private readonly LiquidContainer _outletContainer = new();
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
        
    }
    
    
    
    public IReadOnlyList<T> GetFluidContainers<T>() where T : class, IFluidContainer, new()
    {
        var l = new List<T>();
        try
        {
            l.Add(_inletContainer as T ?? throw new NullReferenceException());
            l.Add(_outletContainer as T ?? throw new NullReferenceException());
        }
        catch
        {
            return ImmutableList<T>.Empty;
        }

        return l;
    }

    public IReadOnlyList<T> GetFluidContainersByGroup<T>(string groupName) where T : class, IFluidContainer, new()
    {
        if (GetPrefContainerByGroup<T>(groupName) is { } container)
            return new List<T>()
            {
                container
            };
        return ImmutableList<T>.Empty;
    }

    public T? GetPrefContainerByGroup<T>(string groupName) where T : class, IFluidContainer, new()
    {
        if (groupName == ILiquidData.SymbolConnInput)
            return _inletContainer as T ?? null;
        if (groupName == ILiquidData.SymbolConnOutput)
            return _outletContainer as T ?? null;
        return null;
    }

    public override void Update(float deltaTime, Camera cam)
    {
        base.Update(deltaTime, cam);
        _ticksUntilUpdate--;
        if (_ticksUntilUpdate < 1)
        {
            _ticksUntilUpdate = IFluidDevice.WaitTicksBetweenUpdates;
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