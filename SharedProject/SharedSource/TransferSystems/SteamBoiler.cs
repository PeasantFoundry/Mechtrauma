using Barotrauma;
using Barotrauma.Items.Components;

namespace Mechtrauma.TransferSystems;

public partial class SteamBoiler : Powered, IFluidDevice
{
    #region VARS

    [Editable(1,10), Serialize(3, IsPropertySaveable.No, "Wait time between net updates.")]
    public int UpdateTicksDelay { get; set; }

    private int _updateWaitTickRemaining = 0;
    private readonly LiquidContainer _inletWaterContainer = new();
    private readonly VaporContainer _outletSteamContainer = new();

    #endregion
    
    public SteamBoiler(Item item, ContentXElement element) : base(item, element)
    {
        this.IsActive = true;
    }
    
    public IReadOnlyList<T> GetFluidContainers<T>() where T : IFluidContainer
    {
        throw new NotImplementedException();
    }

    public IReadOnlyList<T> GetFluidContainersByGroup<T>(string groupName) where T : IFluidContainer
    {
        throw new NotImplementedException();
    }

    public T GetPrefContainerByGroup<T>(string groupName) where T : IFluidContainer
    {
        throw new NotImplementedException();
    }

    public override float GetCurrentPowerConsumption(Connection connection = null)
    {
        return base.GetCurrentPowerConsumption(connection);
    }

    public override void OnMapLoaded()
    {
        base.OnMapLoaded();
    }

    public override void Update(float deltaTime, Camera cam)
    {
        base.Update(deltaTime, cam);
        _updateWaitTickRemaining--;
        if (_updateWaitTickRemaining < 1)
        {
            _updateWaitTickRemaining = UpdateTicksDelay;
            UpdateSteamGeneration();
        }
    }

    private void UpdateSteamGeneration()
    {
        // convert liquid to vapor
        
    }
}