using ModdingToolkit;

using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Text;

namespace Mechtrauma
{
    public partial class Plugin : IAssemblyPlugin
    {
        /// <summary>
        /// Plugin Info.
        /// </summary>
        public static readonly PluginInfo PluginInfo = new("Mechtrauma", "1.0", ImmutableArray<string>.Empty);

        public PluginInfo GetPluginInfo() => PluginInfo;

        public void Initialize()
        {
            changePowerRules();
#if CLIENT
            ClientInitialize();
#endif

        }

        public void OnLoadCompleted()
        {
            // After all plugins have loaded
        }

        public void Dispose()
        {
            // Cleanup your mod
            throw new NotImplementedException();
        }
    }
}
