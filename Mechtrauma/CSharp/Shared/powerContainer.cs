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

            // Modified power container for steam boilers
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.PowerContainer", 
            typeof(Barotrauma.Items.Components.PowerContainer).GetMethod("GetCurrentPowerConsumption", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {

                Connection connection = (Connection)args["connection"];
                
                // If marked for not outputting, don't output power
                if (connection.IsPower && connection.IsOutput && ((PowerContainer)self).Item.HasTag("batterydisabled")) {
                    CurrPowerOutputProperty.SetValue(self, 0.0f);
                    return 0.0f;
                }
                else if (connection.IsPower && !connection.IsOutput && ((PowerContainer)self).Item.HasTag("MechtraumaBoiler")) {

                    // Scale the power consumption based on the 5% of the boilers charge to 3 times the power consumption
                    // This should cause a short brown out when the boiler is empty and starting up
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

            // Adjsut the maxout for the steam boiler to scale below 25%
            // This informs other steam boilers on the grid
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.PowerContainer", 
            typeof(Barotrauma.Items.Components.PowerContainer).GetMethod("MinMaxPowerOut", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                PowerContainer myself = (PowerContainer)self;

                // Arguments are just broken for this function don't use!
                //Connection connection = args["connection"] as Connection;
                //float load = (float)args["load"]; 

                //connection != null && connection.IsPower && connection.IsOutput &&
                // connection object is protected so we can't access it. Otherwise memory violation
                if (myself.Item.HasTag("MechtraumaBoiler")) {
                    float maxOut = myself.MaxOutPut;

                    // Scale the output capabilities down when below 25% charge
                    if (myself.ChargePercentage <= 25) {
                        maxOut = myself.MaxOutPut * myself.ChargePercentage / 25;
                    }

                    maxOut = MathHelper.Clamp(maxOut, 0, myself.MaxOutPut);
                    return new PowerRange(0, maxOut);
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);

            // Modify the steam boiler to output extra power when above 75% charge
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.PowerContainer", 
            typeof(Barotrauma.Items.Components.PowerContainer).GetMethod("GetConnectionPowerOut", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {

                Connection connection = (Connection)args["connection"];
                PowerRange minMaxPower = (PowerRange)args["minMaxPower"];
                PowerContainer myself = (PowerContainer)self;
                float power = (float)args["power"];
                float load = (float)args["load"];

                // Ensure its a steam boiler and output connection
                if (connection.IsPower && connection.IsOutput && myself.Item.HasTag("MechtraumaBoiler")) {
                    // Calculate the normal max power output
                    float maxOut = myself.MaxOutPut;
                    if (myself.ChargePercentage <= 25) {
                        maxOut = myself.MaxOutPut * myself.ChargePercentage / 25;
                    }

                    maxOut = MathHelper.Clamp(maxOut, 0, myself.MaxOutPut);

                    float loadleft = load - power;

                    // scale the load above 75% charge to cause a overload
                    if (myself.ChargePercentage >= 75) {
                        loadleft = (load * myself.ChargePercentage / 75 ) - power;
                    }

                    // Output power taking in account other boilers
                    float powerOutValue = 0;
                    if (minMaxPower.Max > 0) {
                        powerOutValue = MathHelper.Clamp(loadleft / minMaxPower.Max, 0, 1) * maxOut;
                    }

                    // Update power output value for status effects
                    CurrPowerOutputProperty.SetValue(self, powerOutValue);

                    return powerOutValue;
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);
            
            // Modify the steam boiler to not absorb the extra initial spike in power on the dry startup
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.PowerContainer", 
            typeof(Barotrauma.Items.Components.PowerContainer).GetMethod("GridResolved", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                PowerContainer myself = (PowerContainer)self;
                Connection connection = (Connection)args["conn"];

                if (connection.IsPower && !connection.IsOutput && myself.Item.HasTag("MechtraumaBoiler")) {
                    // Cap the max input draw to prevent extra charge on initial startup
                    float loadIn = MathHelper.Clamp(myself.CurrPowerConsumption, 0, myself.MaxRechargeSpeed);
                    myself.Charge += (loadIn * myself.Voltage) / 60 * UpdateInterval * myself.Efficiency;

                    return false;
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);
        }
    }
}