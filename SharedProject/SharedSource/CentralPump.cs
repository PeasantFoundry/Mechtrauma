using ModdingToolkit;

using System;
using Barotrauma;
using Barotrauma.Networking;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Barotrauma.Items.Components;
using System.Linq;
using System.Globalization;

namespace Mechtrauma
{
    class CentralPump : BatteryPump {
        public float HullPercentage 
        {
            get => hullPercentage;
            set => hullPercentage = value;
        }
        private float hullPercentage;

        Connection? waterGateIn;

        public CentralPump(Item item, ContentXElement element) : base(item, element) {
            // call base constructor
        }

        public override void Update(float deltaTime, Camera cam) {
            pumpSpeedLockTimer -= deltaTime;
            isActiveLockTimer -= deltaTime;

            if (!IsActive) {
                return;
            }

            if (TargetLevel != null) {
                flowPercentage = ((float)TargetLevel - HullPercentage);
            }

            Item? battery = getBackupBattery();
            if (!HasPower)
            {
                if (BatteryPowerable && battery != null && battery.Condition > 0.0f)
                {
                    usingBattery = true;
                    battery.Condition -= deltaTime * Math.Abs(flowPercentage / 100.0f);
                }
                else
                {
                    usingBattery = false;
                    return;
                }
            }
            else
            {
                usingBattery = false;
            }

            UpdateProjSpecific(deltaTime);

            ApplyStatusEffects(ActionType.OnActive, deltaTime, null);

            float powerFactor = Math.Min(currPowerConsumption <= 0.0f || MinVoltage <= 0.0f ? 1.0f : Voltage, MaxOverVoltageFactor);
            if (usingBattery)
            {
                powerFactor = 1.0f;
            }


            float flow = FlowPercentage / 100.0f * item.StatManager.GetAdjustedValue(ItemTalentStats.PumpMaxFlow, MaxFlow) * powerFactor;

            //Prevent water flow if there is no water gates connected
            if (waterGateIn == null || waterGateIn.Grid == null || waterGateIn.Grid.Voltage < 0.5f || !HasMotor)
            {
                flow = 0.0f;
            }

            if (item.GetComponent<Repairable>() is { IsTinkering: true } repairable)
            {
                flow *= 1f + repairable.TinkeringStrength * 4.0f;
            }

            flow = item.StatManager.GetAdjustedValue(ItemTalentStats.PumpSpeed, flow);

            //less effective when in a bad condition
            flow *= MathHelper.Lerp(0.5f, 1.0f, item.Condition / item.MaxCondition);

            currFlow = flow;
        }

        public override void OnItemLoaded()
        {
            base.OnItemLoaded();
            foreach (KeyValuePair<string, Connection> pair in item.connections)
            {
                if (pair.Key.StartsWith("power") && pair.Value != null && !pair.Value.IsOutput)
                {
                    powerIn = pair.Value;
                } else if (pair.Key.StartsWith("waterGate") && pair.Value != null && !pair.Value.IsOutput)
                {
                    waterGateIn = pair.Value;
                }
            }
        }

        /// <summary>
        /// Power consumption of the Pump. Only consume power when active and adjust consumption based on condition.
        /// </summary>
        public override float GetCurrentPowerConsumption(Connection connection)
        {
            //There shouldn't be other power connections to this
            if (!IsActive)
            {
                return 0;
            }

            if (connection == powerIn) {
                if (!HasMotor)
                {
                    return 0;
                }

                currPowerConsumption = powerConsumption * Math.Abs(FlowPercentage / 100.0f);
                //pumps consume more power when in a bad condition
                item.GetComponent<Repairable>()?.AdjustPowerConsumption(ref currPowerConsumption);

                return currPowerConsumption;
            }

            return -1;
        }

        new void UpdateProjSpecific(float deltaTime) {
            // Place holder
        }

        
        public override PowerRange MinMaxPowerOut(Connection connection, float load = 0) {
            if (connection == powerOut) {
                return new PowerRange(0, MaxFlow);
            }
            return PowerRange.Zero;
        }

        // Pump will output positive or negative power to indicate flow direction
        public override float GetConnectionPowerOut(Connection connection, float power, PowerRange minMaxPower, float load) {
            if (connection == powerOut) {
                return MathHelper.Clamp(currFlow, -MaxFlow, MaxFlow);
            }
            return 0.0f;
        }

        public override void ReceiveSignal(Signal signal, Connection connection)
        {
            if (Hijacked) { return; }

            base.ReceiveSignal(signal, connection);

            if (connection.Name == "hull_percentage")
            {
                if (float.TryParse(signal.value, NumberStyles.Any, CultureInfo.InvariantCulture, out float tempTarget))
                {
                    HullPercentage = MathHelper.Clamp(tempTarget, 0.0f, 105.0f);
                }
            }
        }

    }
}