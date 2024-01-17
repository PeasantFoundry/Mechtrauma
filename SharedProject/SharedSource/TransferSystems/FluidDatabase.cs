using Barotrauma;

namespace Mechtrauma.TransferSystems;

public class FluidDatabase
{
    private static FluidDatabase _instance;
    public static FluidDatabase Instance
    {
        [MethodImpl(MethodImplOptions.Synchronized)]
        get { return _instance ??= new(); }
    }

    private readonly Dictionary<(string, FluidProperties.PhaseType), FluidProperties> _fluidPropertiesMap = new();

    public void RegisterFluid(FluidProperties prop, bool overwrite = false)
    {
        if (_fluidPropertiesMap.ContainsKey((prop.Identifier, prop.Phase)))
        {
            if (overwrite)
            {
                _fluidPropertiesMap[(prop.Identifier, prop.Phase)] = prop;
                return;
            }
            else
            {
                ModUtils.Logging.PrintError($"FluidDatabase::RegisterFluid() | Attempted to register fluid that already exists! {prop.Identifier}, {prop.Phase}");
                return;
            }
        }
        
        _fluidPropertiesMap[(prop.Identifier, prop.Phase)] = prop;
    }

    public FluidProperties? GetFluidProperties(string identifier, FluidProperties.PhaseType phase)
    {
        if (!_fluidPropertiesMap.ContainsKey((identifier, phase)))
        {
            ModUtils.Logging.PrintWarning($"Could not find fluid with identifier {identifier} and phase {phase}");
            return null;
        }
        
        return _fluidPropertiesMap[(identifier, phase)];
    }

}