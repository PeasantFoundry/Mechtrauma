/***
Modifies power containers so their output can be turned off
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

        // Add extra functionality to Powered components to absorb power if item tag "powerabsorber" is present
        private void addPowerAbsorber() {

            // Make power absorber take damage based on percentage of power absorbed
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("Update", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                Powered powered = (Powered)self;
                float deltaTime = (float)args["deltaTime"];

                // May cause desyncing condition issues 
                if (powered.Item.HasTag("powerabsorber")) {
                    // Check if the device should take damage
                    if (powered.Item.Repairables.Any() && powered.Item.Condition > 0.0f && powered.CurrPowerConsumption < 0) {
                        // calculate the amount of damage to be done
                        float damageCondition = MathHelper.Clamp(powered.CurrPowerConsumption / powered.PowerConsumption * deltaTime * 10, -1, 0);
                        powered.Item.Condition += damageCondition;
                    }
                }

                return null;
            }, LuaCsHook.HookMethodType.After, this);

            // Flag the power absorber input as being a power source device
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("GetCurrentPowerConsumption", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                Powered powered = (Powered)self;
                Connection conn = (Connection)args["connection"];

                // Check if power absorber and is input connection
                if (powered.Item.HasTag("powerabsorber") && conn != null && !conn.IsOutput) {
                    // If not broken then flag as power source
                    return powered.Item.Condition > 0.0f ? -1.0f : 0.0f;
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);

            // Inform other power absorbers of each other so they can work together
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("MinMaxPowerOut", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                Powered powered = (Powered)self;
                // Note for some reason the args are completely broken on this function, Do not use them!

                if (powered.Item.HasTag("powerabsorber")) {
                    // Calculate max power sink, scales down when condition is below 5%
                    float scaler = MathHelper.Min(powered.Item.Condition / 5, 1.0f);
                    return new PowerRange(0, powered.PowerConsumption * scaler);
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);

            // Calculate how much power this device will absorb
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("GetConnectionPowerOut", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                Powered powered = (Powered)self;
                Connection conn = (Connection)args["conn"];
                PowerRange minMaxPower = (PowerRange)args["minMaxPower"];
                float load = (float)args["load"];
                float power = (float)args["power"];

                // Ensure its a power absorber and for the input connection
                if (powered.Item.HasTag("powerabsorber") && conn != null && !conn.IsOutput) {
                    float maxConsumption = powered.PowerConsumption * MathHelper.Min(powered.Item.Condition / 5, 1.0f);
                    float powerexcess = MathHelper.Max(power - load, 0.0f);
                    float powerAbsorbed = 0.0f;

                    // Prevent NaN errors
                    if (minMaxPower.Max > 0) {
                        // Calculate how much power to absorb accounting for other power absorbers
                        powerAbsorbed = -MathHelper.Clamp(powerexcess / minMaxPower.Max * maxConsumption, 0.0f, maxConsumption);
                    }

                    // Update CurrPowerConsumption for status effects to be informed
                    powered.CurrPowerConsumption = powerAbsorbed;
                    return powerAbsorbed;
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);
        }
    }
}