using Barotrauma;
using Barotrauma.Items.Components;

namespace Mechtrauma.TransferSystems;

public partial class SteamBoiler : Powered, IFluidDevice<LiquidContainer, LiquidData>, IFluidDevice<VaporContainer, VaporData>
{
    #region VARS

    private int _updateWaitTickRemaining = 0;
    private readonly LiquidContainer _inletWaterContainer = new();
    private readonly VaporContainer _outletSteamContainer = new();

    #endregion
    
    public SteamBoiler(Item item, ContentXElement element) : base(item, element)
    {
        this.IsActive = true;
    }

    #region INTERFACE_API

    #region LIQUID

    T3 IFluidDevice<LiquidContainer, LiquidData>.GetFluidContainers<T3>()
    {
        throw new NotImplementedException();
    }
    
    T3 IFluidDevice<LiquidContainer, LiquidData>.GetFluidContainersByGroup<T3>(string groupName)
    {
        throw new NotImplementedException();
    }

    LiquidContainer? IFluidDevice<LiquidContainer, LiquidData>.GetPrefContainerByGroup(string groupName)
    {
        throw new NotImplementedException();
    }

    #endregion

    #region VAPOR

    T3 IFluidDevice<VaporContainer, VaporData>.GetFluidContainersByGroup<T3>(string groupName)
    {
        throw new NotImplementedException();
    }

    VaporContainer? IFluidDevice<VaporContainer, VaporData>.GetPrefContainerByGroup(string groupName)
    {
        throw new NotImplementedException();
    }

    T3 IFluidDevice<VaporContainer, VaporData>.GetFluidContainers<T3>()
    {
        throw new NotImplementedException();
    }

    #endregion
    
    #endregion

    

    public FluidProperties.PhaseType OutputPhaseType { get; protected set; }
    public FluidProperties.PhaseType InputPhaseType { get; protected set; }

    public override void Update(float deltaTime, Camera cam)
    {
        base.Update(deltaTime, cam);
        _updateWaitTickRemaining--;
        if (_updateWaitTickRemaining < 1)
        {
            _updateWaitTickRemaining = FluidSystemData.WaitTicksBetweenUpdates;
            UpdateSteamGeneration();
        }
    }

    private void UpdateSteamGeneration()
    {
        // convert liquid to vapor
        
    }
}