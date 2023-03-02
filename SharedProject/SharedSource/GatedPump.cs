using ModdingToolkit;

using System;
using Barotrauma;
using Barotrauma.Networking;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Barotrauma.Items.Components;
using System.Linq;

namespace Mechtrauma
{
    class GatedPump : Pump
    {
        Connection? waterGateOut;

        public GatedPump(Item item, ContentXElement element) : base(item, element)
        {
            // call base constructor
        }

        public override void Update(float deltaTime, Camera cam)
        {
            pumpSpeedLockTimer -= deltaTime;
            isActiveLockTimer -= deltaTime;

            if (!IsActive)
            {
                return;
            }

            currFlow = 0.0f;

            if (TargetLevel != null)
            {
                float hullPercentage = 0.0f;
                if (item.CurrentHull != null)
                {
                    float hullWaterVolume = item.CurrentHull.WaterVolume;
                    float totalHullVolume = item.CurrentHull.Volume;
                    foreach (var linked in item.CurrentHull.linkedTo)
                    {
                        if ((linked is Hull linkedHull))
                        {
                            hullWaterVolume += linkedHull.WaterVolume;
                            totalHullVolume += linkedHull.Volume;
                        }
                    }
                    hullPercentage = hullWaterVolume / totalHullVolume * 100.0f;
                }
                FlowPercentage = ((float)TargetLevel - hullPercentage) * 10.0f;
            }

            if (!HasPower)
            {
                return;
            }

            UpdateProjSpecific(deltaTime);

            ApplyStatusEffects(ActionType.OnActive, deltaTime, null);

            if (item.CurrentHull == null) { return; }

            float powerFactor = Math.Min(currPowerConsumption <= 0.0f || MinVoltage <= 0.0f ? 1.0f : Voltage, MaxOverVoltageFactor);

            float flow = FlowPercentage / 100.0f * item.StatManager.GetAdjustedValue(ItemTalentStats.PumpMaxFlow, MaxFlow) * powerFactor;

            //Prevent water flow if there is no water gates connected
            if (waterGateOut == null || waterGateOut.Grid == null || waterGateOut.Grid.Voltage < 0.5f)
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

            currFlow *= MathHelper.Lerp(0.5f, 1.0f, item.Condition / item.MaxCondition);

            item.CurrentHull.WaterVolume += currFlow * deltaTime * Timing.FixedUpdateRate;
            if (item.CurrentHull.WaterVolume > item.CurrentHull.Volume) { item.CurrentHull.Pressure += 30.0f * deltaTime; }
        }

        public override void OnItemLoaded()
        {
            base.OnItemLoaded();
            foreach (KeyValuePair<string, Connection> pair in item.connections)
            {
                if (pair.Key.StartsWith("waterGate") && pair.Value != null)
                {
                    waterGateOut = pair.Value;
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

            if (connection == powerIn)
            {
                currPowerConsumption = powerConsumption * Math.Abs(FlowPercentage / 100.0f);
                //pumps consume more power when in a bad condition
                item.GetComponent<Repairable>()?.AdjustPowerConsumption(ref currPowerConsumption);

                return currPowerConsumption;
            }

            return 1.0f;
        }

        new void UpdateProjSpecific(float deltaTime)
        {
            // Place holder
        }

    }
}