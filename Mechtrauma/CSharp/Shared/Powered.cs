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

        // Change the power container to disable output if not active
        private void addPowerAbsorber() {

            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("Update", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                Powered powered = (Powered)self;
                float deltaTime = (float)args["deltaTime"];

                // May cause desyncing condition issues 
                if (powered.Item.HasTag("powerabsorber")) {
                    if (powered.Item.Repairables.Any() && powered.Item.Condition > 0.0f && powered.CurrPowerConsumption < 0) {
                        float damageCondition = MathHelper.Clamp(powered.CurrPowerConsumption / powered.PowerConsumption * deltaTime * 10, -1, 0);
                        powered.Item.Condition += damageCondition;
                    }
                }

                return null;
            }, LuaCsHook.HookMethodType.After, this);

            // Changes the power connections limits to create steam and kinetic grids as well as the power grid.
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("GetCurrentPowerConsumption", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                Powered powered = (Powered)self;
                Connection conn = (Connection)args["connection"];
                if (powered.Item.HasTag("powerabsorber") && conn != null && !conn.IsOutput) {
                    return powered.Item.Condition > 0.0f ? -1.0f : 0.0f;
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);

            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("MinMaxPowerOut", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                Powered powered = (Powered)self;
                if (powered.Item.HasTag("powerabsorber")) {
                    float scaler = MathHelper.Min(powered.Item.Condition / 5, 1.0f);
                    return new PowerRange(0, powered.PowerConsumption * scaler);
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);

            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("GetConnectionPowerOut", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                Powered powered = (Powered)self;
                Connection conn = (Connection)args["conn"];
                PowerRange minMaxPower = (PowerRange)args["minMaxPower"];
                float load = (float)args["load"];
                float power = (float)args["power"];

                if (powered.Item.HasTag("powerabsorber") && conn != null && !conn.IsOutput) {
                    float maxConsumption = powered.PowerConsumption * MathHelper.Min(powered.Item.Condition / 5, 1.0f);
                    float powerexcess = MathHelper.Max(power - load, 0.0f);
                    float powerAbsorbed = -MathHelper.Clamp(powerexcess / minMaxPower.Max * maxConsumption, 0.0f, maxConsumption);

                    ((Powered)self).CurrPowerConsumption = powerAbsorbed;
                    return powerAbsorbed;
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);
        }
    }
}