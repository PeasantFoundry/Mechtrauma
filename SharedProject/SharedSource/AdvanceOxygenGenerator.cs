/***
Modified power container that can be turned on and off
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
    class AdvanceOxygenGenerator : OxygenGenerator {

        const float bottleLitres = 200.0f; 

        private float capacity = 0;

        [Editable, Serialize(0, IsPropertySaveable.Yes, description: "Capacity of the internal oxygen tank (Litres)", alwaysUseInstanceValues: true)]
        public float Capacity {
            get => capacity;
            set => capacity = MathHelper.Max(value, 0);
        }

        public int StoredPercentage {
            get => (int)Math.Ceiling(Stored / Capacity * 100);
        }

        private float stored = 0;
        [Editable, Serialize(1000, IsPropertySaveable.Yes, description: "Amount of Oxygen stored (Litres)", alwaysUseInstanceValues: true)]
        public float Stored {
            get => stored;
            set => stored = MathHelper.Clamp(value, 0, Capacity);
        }

        private float prevStored = 0;
    
        [Editable, Serialize(3, IsPropertySaveable.Yes, description: "Rate to fill bottles in percentage per second (Varies with bottle quality)", alwaysUseInstanceValues: true)]
        public float RefillRate {
            get => refillRate;
            set => refillRate = MathHelper.Max(value, 0);
        }
        private float refillRate = 0;

        public float adjustedGeneratedAmount {
            get {
                float percentage = prevStored / Capacity;
                float adjusted = GeneratedAmount;

                // Scale the output capabilities down when below 25% charge
                if (percentage < 0.05f) {
                    adjusted *= percentage / 0.05f;
                }

                return MathHelper.Clamp(adjusted, 0, GeneratedAmount);
            }
        }

        
        public AdvanceOxygenGenerator(Item item, ContentXElement element) : base(item, element) {
            // call base constructor
            prevStored = Stored;
        }

        public override void Update(float deltaTime, Camera cam)
        {
            UpdateOnActiveEffects(deltaTime);

            if (Voltage < MinVoltage && PowerConsumption > 0)
            {
                return;
            }

            // Refill bottles
            /*
            ItemInventory inv = item.OwnInventory;
            if (inv != null && Capacity > 0.0f) {
                foreach (Item invItem in inv.Items)
                {
                    if (!invItem.IsFullCondition) 
                    {
                        float added = Math.Min(deltaTime * RefillRate, Stored * 100 / bottleLitres);
                        invItem.Condition = Math.Min(invItem.Condition + added, invItem.MaxCondition);
                        Stored -= added * bottleLitres / 100;
                    }

                    if (Stored <= 0.0f) {
                        break;
                    }
                }
            }


            CurrFlow = 0.0f;

            if (item.CurrentHull == null) { return; }
            

            CurrFlow = Math.Min(PowerConsumption > 0 ? Voltage : 1.0f, MaxOverVoltageFactor) * generatedAmount * 100.0f;
            */

        }

        // Power consumption starts high during initial charge up then drops off to normal scaling after around 5% charge
        public override float GetCurrentPowerConsumption(Connection connection) {
            if (!IsActive) {
                return 0;
            }

            if (connection == this.powerIn)
            {
                // Base line 10% of max power consumption, linearly scale down as tank fills
                float consumption = powerConsumption * MathHelper.Clamp(1.1f - Stored / Capacity, 0.1f, 1.0f);

                //consume more power when in a bad condition
                item.GetComponent<Repairable>()?.AdjustPowerConsumption(ref consumption);
                return consumption;
            }
            else 
            {
                return Stored > 0 ? -1.0f : 0.0f;
            }
        }

        public override PowerRange MinMaxPowerOut(Connection connection, float load = 0) {
            if (connection == powerOut) {
                float maxOut = GeneratedAmount;
                float percentage = prevStored / Capacity;

                // Scale the output capabilities down when below 25% charge
                if (percentage < 0.05f) {
                    maxOut *= percentage / 0.05f;
                }

                maxOut = MathHelper.Clamp(maxOut, 0, GeneratedAmount);
                return new PowerRange(0, maxOut);
            }
            return PowerRange.Zero;
        }

        // Scale the oxygen output when below 5%
        public override float GetConnectionPowerOut(Connection connection, float power, PowerRange minMaxPower, float load) {
            if (connection == powerOut) {
                float maxOut = GeneratedAmount;
                float percentage = prevStored / Capacity;

                // Scale the output capabilities down when below 25% charge
                if (percentage < 0.05f) {
                    maxOut *= percentage / 0.05f;
                }

                maxOut = MathHelper.Clamp(maxOut, 0, GeneratedAmount);

                float output = 0.0f;
                if (minMaxPower.Max > 0) {
                    output = MathHelper.Clamp((load - power) / minMaxPower.Max, 0.0f, 1.0f) * maxOut;
                }
                CurrFlow = output;
                return output;
            }
            return 0.0f;
        }

        // Clamp input consumption so that initial charge up doesn't speed up the charge rate
        public override void GridResolved(Connection conn)
        {
            /*
            if (conn == powerIn)
            {
                //Increase charge based on how much power came in from the grid
                Stored += ((CurrPowerConsumption / powerConsumption  * GeneratedAmount) * MathHelper.Min(Voltage, MaxOverVoltageFactor)) / 500 * UpdateInterval * Efficiency;
            }
            else
            {
                //Decrease charge based on how much power is leaving the device
                Stored = Math.Clamp(Stored - CurrFlow / 500 * UpdateInterval, 0, Capacity);
                prevStored = Stored;
            }
            */
        }

    }
}