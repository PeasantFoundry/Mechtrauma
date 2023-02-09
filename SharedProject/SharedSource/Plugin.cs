using Barotrauma;
using ModdingToolkit;

using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using MoonSharp.Interpreter;
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
            Utils.Logging.PrintMessage("Mechtrauma starting...");
            InitUserData();

#if SERVER
            //GameMain.Server?.SendChatMessage("Started Mechtrauma");

#elif CLIENT
            //GameMain.Client?.SendChatMessage("Started Mechtrauma");
            ClientInitialize();
#endif
        }

        public void OnLoadCompleted()
        {
            // After all plugins have loaded
        }

        private void InitUserData()
        {
            UserData.RegisterType<Configuration>();
            UserData.RegisterType<Configuration.Settings_General>();
            UserData.RegisterType<Configuration.Settings_Advanced>();
            UserData.RegisterType<Configuration.Settings_Experimental>();

            GameMain.LuaCs.Lua.Globals["MTConfig"] = Configuration.Instance;
        }

        private void UnloadUserData()
        {
            GameMain.LuaCs.Lua.Globals["MTConfig"] = null;

            UserData.UnregisterType<Configuration.Settings_Experimental>();
            UserData.UnregisterType<Configuration.Settings_Advanced>();
            UserData.UnregisterType<Configuration.Settings_General>();
            UserData.UnregisterType<Configuration>();
        }

        public void Dispose()
        {
            UnloadUserData();
            // stopping code, e.g. save custom data
#if SERVER
            // server-side code

#elif CLIENT
                // client-side code
                
#endif
        }
    }
}
