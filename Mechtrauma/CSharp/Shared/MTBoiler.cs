/***
Modified Power container designed to be used as an advance boiler
***/
using System;
using Barotrauma;
using Barotrauma.Networking;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Barotrauma.Items.Components;
using System.Linq;

namespace Barotrauma.Items.Components 
{
    class MTBoiler : PowerContainer {

        public MTBoiler(Item item, ContentXElement element) : base(item, element) {
            // call base constructor
        }

        // Power consumption starts high during initial charge up then drops off to normal scaling after around 5% charge
        public override float GetCurrentPowerConsumption(Connection connection) {
            if (connection == powerIn) {
                float newLoad = 0;
                if (Capacity - Charge <= 1) {
                    newLoad = (Capacity - Charge) * RechargeSpeed;
                } else {
                    newLoad = RechargeSpeed * (1 + (float)Math.Pow(3, 0.0030103f - ChargePercentage));
                }

                if (float.IsNegative(newLoad)) {
                    newLoad = 0.0f;
                }

                return newLoad;
            } else {
                return base.GetCurrentPowerConsumption(connection);
            }
        }

        public override PowerRange MinMaxPowerOut(Connection connection, float load = 0) {
            if (connection == powerOut) {
                float maxOut = MaxOutPut;

                // Scale the output capabilities down when below 25% charge
                if (ChargePercentage <= 25) {
                    maxOut *= ChargePercentage / 25;
                }

                // Disable output when device is below 10% condition
                if (item.Condition < 10) {
                    maxOut = 0;
                }

                maxOut = MathHelper.Clamp(maxOut, 0, MaxOutPut);
                return new PowerRange(0, maxOut);
            }
            return base.MinMaxPowerOut(connection, load);
        }

        // Past 75% charge scale the load to cause overloading of the grid up to 2x at 100% charge
        public override float GetConnectionPowerOut(Connection connection, float power, PowerRange minMaxPower, float load) {
            float loadScaler = 1;
            if (connection == powerOut && ChargePercentage >= 75) {
                loadScaler += (ChargePercentage - 75) / 25;
            }
            return base.GetConnectionPowerOut(connection, power, minMaxPower, load * loadScaler);
        }

        // Clamp input consumption so that initial charge up doesn't speed up the charge rate
        public override void GridResolved(Connection conn)
        {
            if (conn == powerIn)
            {
                //Increase charge based on how much power came in from the grid and clamped to the Max Charge Rate
                Charge += (Math.Clamp(CurrPowerConsumption, 0, RechargeSpeed) * Voltage) / 60 * UpdateInterval * Efficiency;
            }
            else
            {
                base.GridResolved(conn);
            }
        }
    }
}

