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
        private void modifyPowerContainers() {
            PropertyInfo CurrPowerOutputProperty = typeof(Barotrauma.Items.Components.PowerContainer).GetProperty("CurrPowerOutput", BindingFlags.Instance | BindingFlags.Public);

            // Changes the power connections limits to create steam and kinetic grids as well as the power grid.
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.PowerContainer", 
            typeof(Barotrauma.Items.Components.PowerContainer).GetMethod("GetCurrentPowerConsumption", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {

                Connection connection = (Connection)args["connection"];
                
                if (connection.IsPower && connection.IsOutput && ((PowerContainer)self).Item.HasTag("batterydisabled")) {
                    CurrPowerOutputProperty.SetValue(self, 0.0f);
                    return 0.0f;
                }
                else if (connection.IsPower && !connection.IsOutput && ((PowerContainer)self).Item.HasTag("MechtraumaBoiler")) {
                    float newLoad = 0;
                    if (((PowerContainer)self).Capacity - ((PowerContainer)self).Charge <= 1) {
                        newLoad = (((PowerContainer)self).Capacity - ((PowerContainer)self).Charge) * ((PowerContainer)self).RechargeSpeed;
                    } else {
                        newLoad = ((PowerContainer)self).RechargeSpeed * (1 + (float)Math.Pow(3, 0.0030103f - ((PowerContainer)self).ChargePercentage));
                    }

                    if (float.IsNegative(newLoad)) {
                        newLoad = 0.0f;
                    }

                    return newLoad;
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);

            float UpdateInterval = (float)typeof(Barotrauma.Items.Components.Powered).GetField("UpdateInterval", BindingFlags.Static | BindingFlags.NonPublic).GetValue(null);

            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.PowerContainer", 
            typeof(Barotrauma.Items.Components.PowerContainer).GetMethod("MinMaxPowerOut", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                PowerContainer myself = (PowerContainer)self;
                //Connection connection = args["connection"] as Connection;
                float load = (float)args["load"]; // Load is busted just like connection

                //connection != null && connection.IsPower && connection.IsOutput &&
                // connection object is protected so we can't access it. Otherwise memory violation
                if (myself.Item.HasTag("MechtraumaBoiler")) {
                    float maxOut = myself.MaxOutPut;

                    if (myself.ChargePercentage <= 25) {
                        maxOut = myself.MaxOutPut * myself.ChargePercentage / 25;
                    }

                    maxOut = MathHelper.Clamp(maxOut, 0, myself.MaxOutPut);
                    return new PowerRange(0, maxOut);
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);

            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.PowerContainer", 
            typeof(Barotrauma.Items.Components.PowerContainer).GetMethod("GetConnectionPowerOut", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {

                Connection connection = (Connection)args["connection"];
                PowerRange minMaxPower = (PowerRange)args["minMaxPower"];
                PowerContainer myself = (PowerContainer)self;
                float power = (float)args["power"];
                float load = (float)args["load"];

                if (connection.IsPower && connection.IsOutput && myself.Item.HasTag("MechtraumaBoiler")) {
                    
                    float maxOut = myself.MaxOutPut;
                    if (myself.ChargePercentage <= 25) {
                        maxOut = myself.MaxOutPut * myself.ChargePercentage / 25;
                    }

                    maxOut = MathHelper.Clamp(maxOut, 0, myself.MaxOutPut);
                    float loadleft = load - power;
                    if (myself.ChargePercentage >= 75) {
                        loadleft = (load * myself.ChargePercentage / 75 ) - power;
                    }

                    float powerOutValue = 0;
                    if (minMaxPower.Max > 0) {
                        powerOutValue = MathHelper.Clamp(loadleft / minMaxPower.Max, 0, 1) * maxOut;
                    }

                    CurrPowerOutputProperty.SetValue(self, powerOutValue);
                    
                    return powerOutValue;
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);

            
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.PowerContainer", 
            typeof(Barotrauma.Items.Components.PowerContainer).GetMethod("GridResolved", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {

                Connection connection = (Connection)args["conn"];

                if (connection.IsPower && !connection.IsOutput && ((PowerContainer)self).Item.HasTag("MechtraumaBoiler")) {
                    float loadIn = MathHelper.Clamp(((PowerContainer)self).CurrPowerConsumption, 0, ((PowerContainer)self).MaxRechargeSpeed);

                    ((PowerContainer)self).Charge += (loadIn * ((PowerContainer)self).Voltage) / 60 * UpdateInterval * ((PowerContainer)self).Efficiency;

                    return false;
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);
        }
    }
}