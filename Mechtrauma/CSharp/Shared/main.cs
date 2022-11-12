using System;
using Barotrauma;
using System.Reflection;
using System.Collections.Generic;
using System.Linq;
 
namespace Mechtrauma {
    partial class Mechtrauma: ACsMod {
        public Mechtrauma() {
            //LuaCsSetup.PrintCsMessage("Started Mechtrauma");
            
            changePowerRules();

            #if SERVER
                //GameMain.Server?.SendChatMessage("Started Mechtrauma");

            #elif CLIENT
                //GameMain.Client?.SendChatMessage("Started Mechtrauma");
                changeConnectionGUI();
            #endif
        }
 
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