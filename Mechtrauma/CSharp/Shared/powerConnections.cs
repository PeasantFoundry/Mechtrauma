/***
Modifies the rules of power connections to allow for there to be steam and kinetic grids.
Lots of other functions have to be tampered with to allow for proper implementation of this.
***/
using System;
using Barotrauma;
using Barotrauma.Networking;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Barotrauma.Items.Components;
using System.Linq;
 
namespace Mechtrauma {
    partial class Mechtrauma: ACsMod {

        // Change the power connection rules to isolate the steam, power and kinetic networks.
        private void changePowerRules() {
            // Changes the power connections limits to create steam and kinetic grids as well as the power grid.
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("ValidPowerConnection", BindingFlags.Static | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {

                Connection conn1 = (Connection)args["conn1"];
                Connection conn2 = (Connection)args["conn2"];

                // Don't connect devices that aren't on the power pin  or are broken
                if (!conn1.IsPower || !conn2.IsPower || conn1.Item.Condition <= 0.0f || conn2.Item.Condition <= 0.0f ||
                 conn1.Item.HasTag("disconnected") || conn2.Item.HasTag("disconnected")) {
                    return false;
                } 

                // Check if its a steam connection, if so, only connect steam connections
                if (conn1.Name.StartsWith("steam") || conn2.Name.StartsWith("steam")) {
                    return conn1.Name.StartsWith("steam") && conn2.Name.StartsWith("steam") && (
                        conn1.IsOutput != conn2.IsOutput || 
                        conn1.Name == "steam" || 
                        conn2.Name == "steam" ||
                        conn1.Item.HasTag("steamjb") ||
                        conn2.Item.HasTag("steamjb")
                    );
                } else if (conn1.Name.StartsWith("kinetic") || conn2.Name.StartsWith("kinetic")) {
                    // Check if its a kinetic connection, if so, only connect kinetic connections
                    return conn1.Name.StartsWith("kinetic") && conn2.Name.StartsWith("kinetic") && (
                        conn1.IsOutput != conn2.IsOutput || 
                        conn1.Name == "kinetic" || 
                        conn2.Name == "kinetic" ||
                        conn1.Item.HasTag("kineticjb") ||
                        conn2.Item.HasTag("kineticjb")
                    );
                }

                // let the original function handle the rest
                return null;
            }, LuaCsHook.HookMethodType.Before, this);
 
            // Grab the isPower property 
            PropertyInfo isPowerField = typeof(Barotrauma.Items.Components.Connection).GetProperty("IsPower", BindingFlags.Instance | BindingFlags.Public);

            // Change the item connection loading to allow for steam and kinetic networks
            // After the constructor correctly set the isPower property, for the steam and kinetic networks
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Connection", 
            typeof(Barotrauma.Items.Components.Connection).GetConstructor(new[] { typeof(ContentXElement), typeof(ConnectionPanel), typeof(IdRemap) }),
            (object self, Dictionary<string, object> args) => {
                switch(((Barotrauma.Items.Components.Connection)self).Name) {
                    case "steam":
                    case "steam_out":
                    case "steam_in":
                        isPowerField.SetValue(self, true);
                        break;
                    case "kinetic":
                    case "kinetic_out":
                    case "kinetic_in":
                        isPowerField.SetValue(self, true);
                        break;
                }

                return args;
            }, LuaCsHook.HookMethodType.After, this);

            // Make powerIn and powerOut fields publically accessible 
            FieldInfo powerOutField = typeof(Barotrauma.Items.Components.Powered).GetField("powerOut", BindingFlags.Instance | BindingFlags.NonPublic);
            FieldInfo powerInField = typeof(Barotrauma.Items.Components.Powered).GetField("powerIn", BindingFlags.Instance | BindingFlags.NonPublic);

            // Correctly assign the powerIn and powerOut for the steam and kinetic networks
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("OnItemLoaded", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                Item item = (self as Barotrauma.Items.Components.Powered).Item;
                

                if (item.Connections == null) { return args; }

                // Get the highest priority device for this item
                PowerPriority priority = PowerPriority.Default;;
                foreach (var dev in item.GetComponents<Powered>()) {
                    PowerPriority currPrior = PowerPriority.Default;
                    if (dev is RelayComponent) {
                        currPrior = PowerPriority.Relay;
                    } else if (dev is PowerContainer) {
                        currPrior = PowerPriority.Battery;
                    } else if (dev is Reactor) {
                        currPrior = PowerPriority.Reactor;
                    } else if (dev.Item.HasTag("powerabsorber")) {
                        currPrior = (PowerPriority)10;
                    }

                    if (currPrior > priority) {
                        priority = currPrior;
                    }
                }

                // Find the powerIn and powerOut connections and assign them
                foreach (Connection c in item.Connections)
                {
                    if (!c.IsPower) { continue; }

                    c.Priority = priority;
                    switch (c.Name) {
                        case "steam_out":
                        case "kinetic_out":
                            powerOutField.SetValue(self, c);
                            break;
                        case "kinetic_in":
                        case "steam_in":
                            powerInField.SetValue(self, c);
                            break;
                        case "steam":
                        case "kinetic":
                            if (c.IsOutput) {
                                powerOutField.SetValue(self, c);
                            } else {
                                powerInField.SetValue(self, c);
                            }
                            break;
                    }
                }

                return args;
            }, LuaCsHook.HookMethodType.After, this);

            // Remove the power_in pin from the relay check as it causes an uncessary warning that doesn't affect it's functionality
            FieldInfo relayDictField = typeof(Barotrauma.Items.Components.RelayComponent).GetField("connectionPairs", BindingFlags.Static | BindingFlags.NonPublic);
            Dictionary<string, string> relayDict = relayDictField.GetValue(null) as Dictionary<string, string>;
            relayDict.Remove("power_in");
        }
    }
}