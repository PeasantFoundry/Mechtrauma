using ModdingToolkit;

using System;
using Barotrauma;
using Barotrauma.Networking;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Barotrauma.Items.Components;
using System.Linq;
#pragma warning disable CS8625

namespace Mechtrauma
{
    public class CentralPump : Pump {
        public float HullPercentage 
        {
            get => hullPercentage;
            set => hullPercentage = value;
        }
        private float hullPercentage;

        public CentralPump(Item item, ContentXElement element) : base(item, element) {
            // call base constructor
        }

        public override void Update(float deltaTime, Camera cam) {
            pumpSpeedLockTimer -= deltaTime;
            isActiveLockTimer -= deltaTime;

            if (!IsActive) {
                //LuaCsSetup.PrintCsMessage("Drain not active");
                return;
            }

            if (TargetLevel != null) {
                flowPercentage = ((float)TargetLevel - HullPercentage) * 10.0f;
            }

            if (!HasPower) {
                return;
            }

            UpdateProjSpecific(deltaTime);

            ApplyStatusEffects(ActionType.OnActive, deltaTime, null);

            float powerFactor = Math.Min(currPowerConsumption <= 0.0f || MinVoltage <= 0.0f ? 1.0f : Voltage, MaxOverVoltageFactor);

            float flow = FlowPercentage / 100.0f * item.StatManager.GetAdjustedValue(ItemTalentStats.PumpMaxFlow, MaxFlow) * powerFactor;

            if (item.GetComponent<Repairable>() is { IsTinkering: true } repairable)
            {
                flow *= 1f + repairable.TinkeringStrength * 4.0f;
            }

            flow = item.StatManager.GetAdjustedValue(ItemTalentStats.PumpSpeed, flow);

            //less effective when in a bad condition
            flow *= MathHelper.Lerp(0.5f, 1.0f, item.Condition / item.MaxCondition);

            currFlow = flow;
        }

        /// <summary>
        /// Power consumption of the Pump. Only consume power when active and adjust consumption based on condition.
        /// </summary>
        public override float GetCurrentPowerConsumption(Connection connection = null)
        {
            //There shouldn't be other power connections to this
            if (!IsActive)
            {
                return 0;
            }

            if (connection == powerIn) {
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

    }
}