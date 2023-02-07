/***
Main class for Mechtrauma
Initialises the necessary functions and helps make the mod files more managable.
Ensures only specific functions are called if its a client or server
***/
using System;
using Barotrauma;
using System.Reflection;
using System.Collections.Generic;
using System.Linq;
using MoonSharp.Interpreter;

namespace Mechtrauma {
    partial class Mechtrauma: ACsMod {
        public Mechtrauma() {
            ModdingToolkit.Utils.Logging.PrintMessage("Mechtrauma starting...");
            InitUserData();

            #if SERVER
                //GameMain.Server?.SendChatMessage("Started Mechtrauma");

            #elif CLIENT
                //GameMain.Client?.SendChatMessage("Started Mechtrauma");
                //changeConnectionGUI();
            #endif
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
 
        // Place holder
        public override void Stop() {
            
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