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
 
namespace Mechtrauma {
    partial class Mechtrauma: ACsMod {
        public Mechtrauma() {
            //LuaCsSetup.PrintCsMessage("Started Mechtrauma");
            
            // Change the power connection rules to isolate the steam, power, water and kinetic networks.
            changePowerRules();

            #if SERVER
                //GameMain.Server?.SendChatMessage("Started Mechtrauma");

            #elif CLIENT
                //GameMain.Client?.SendChatMessage("Started Mechtrauma");
                changeConnectionGUI();
            #endif
        }
 
        // Place holder
        public override void Stop() {
            // stopping code, e.g. save custom data
             #if SERVER
                // server-side code
                
            #elif CLIENT
                // client-side code
                
            #endif
        }
    }
}