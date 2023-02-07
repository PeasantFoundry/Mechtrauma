/***
Adds grid absorption device that absorb over voltage in turn for damaging themselves
This is primarily utilised by steam regulators
***/
using ModdingToolkit;

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
    class GridAbsorber : Powered {
        [Editable, Serialize(500.0f, IsPropertySaveable.Yes, description: "Max power the device can absorb in an overvoltage event", alwaysUseInstanceValues: true)]
        public float MaxPowerAbsorption { get => maxPowerAbsorption; set => maxPowerAbsorption = value; }
        
        private float maxPowerAbsorption;

        public GridAbsorber(Item item, ContentXElement element) : base(item, element) {
            // call base constructor
        }

        // Update function to damage the device depending on how much power it is absorbing
        public override void Update(float deltaTime, Camera cam) {
            base.Update(deltaTime, cam);

            // Check if the device should take damage
            if (item.Repairables.Any() && item.Condition > 0.0f && CurrPowerConsumption < 0) {
                // calculate the amount of damage to be done
                float damageCondition = MathHelper.Clamp(CurrPowerConsumption / MaxPowerAbsorption * deltaTime * 3, -1, 0);
                item.Condition += damageCondition;
            }
        }

        public override float GetCurrentPowerConsumption(Connection connection) {
            // Check if power absorber and is input connection
            if (connection == powerIn) {
                // If not broken then flag as power source
                return item.Condition > 0.0f ? -1.0f : 0.0f;
            }

            return 0;
        }

        public override PowerRange MinMaxPowerOut(Connection connection, float load) {
            // Indicate max absorption capabilities
            if (connection == powerIn) {
                float scaler = MathHelper.Min(item.Condition / 5, 1.0f);
                return new PowerRange(0, MaxPowerAbsorption * scaler);
            }

            return PowerRange.Zero;
        }

        public override float GetConnectionPowerOut(Connection connection, float power, PowerRange minMaxPower, float load) {
            // Check if input connection
            if (connection == powerIn) {
                float maxConsumption = MinMaxPowerOut(connection, load).Max;
                float powerexcess = MathHelper.Max(power - load, 0.0f);
                float powerAbsorbed = 0.0f;

                // Prevent NaN errors
                if (minMaxPower.Max > 0) {
                    // Calculate how much power to absorb accounting for other power absorbers
                    powerAbsorbed = -MathHelper.Clamp(powerexcess / minMaxPower.Max * maxConsumption, 0.0f, maxConsumption);
                }

                // Update CurrPowerConsumption for status effects to be informed
                CurrPowerConsumption = powerAbsorbed;
                return powerAbsorbed;
            }

            return 0;
        }

    }
}