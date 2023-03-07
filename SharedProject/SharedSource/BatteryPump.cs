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
    public partial class BatteryPump : Pump
    {
        [Editable, Serialize(false, IsPropertySaveable.No, description: "Whether batteries contained will power the pump", alwaysUseInstanceValues: true)]

        public bool BatteryPowerable
        {
            get => batteryPowerable;
            set => batteryPowerable = value;
        }
        private bool batteryPowerable;

        public bool UsingBattery
        {
            get => usingBattery;
        }
        protected bool usingBattery;

        public bool HasMotor
        {
            get
            {
                ItemInventory inv = item.OwnInventory;
                if (inv != null)
                {

                    // Get condition of the first item in the JB inventory
                    Item? invItem = inv.GetItemAt(0);
                    if (invItem?.HasTag("electricmotor") == false)
                    {
                        return false;
                    }

                    return invItem?.Condition > 0.0f;
                }
                return true;
            }
        }

        public BatteryPump(Item item, ContentXElement element) : base(item, element)
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

            Item? battery = getBackupBattery();
            if (!HasPower)
            {
                if (BatteryPowerable && battery != null && battery.Condition > 0.0f)
                {
                    usingBattery = true;
                    battery.Condition -= deltaTime * Math.Abs(flowPercentage / 100.0f);
                } else
                {
                    usingBattery = false;
                    return;
                }
            } else
            {
                usingBattery = false;
            }

            UpdateProjSpecific(deltaTime);

            ApplyStatusEffects(ActionType.OnActive, deltaTime, null);

            if (item.CurrentHull == null) { return; }

            float powerFactor = Math.Min(currPowerConsumption <= 0.0f || MinVoltage <= 0.0f ? 1.0f : Voltage, MaxOverVoltageFactor);
            if (usingBattery)
            {
                powerFactor = 1.0f;
            }

            if (!HasMotor)
            {
                powerFactor = 0.0f;
            }

            currFlow = flowPercentage / 100.0f * item.StatManager.GetAdjustedValue(ItemTalentStats.PumpMaxFlow, MaxFlow) * powerFactor;

            if (item.GetComponent<Repairable>() is { IsTinkering: true } repairable)
            {
                currFlow *= 1f + repairable.TinkeringStrength * TinkeringSpeedIncrease;
            }

            currFlow = item.StatManager.GetAdjustedValue(ItemTalentStats.PumpSpeed, currFlow);

            //less effective when in a bad condition
            currFlow *= MathHelper.Lerp(0.5f, 1.0f, item.Condition / item.MaxCondition);

            item.CurrentHull.WaterVolume += currFlow * deltaTime * Timing.FixedUpdateRate;
            if (item.CurrentHull.WaterVolume > item.CurrentHull.Volume) { item.CurrentHull.Pressure += 30.0f * deltaTime; }
        }

        protected Item? getBackupBattery()
        {
            ItemInventory inv = item.OwnInventory;
            if (inv != null)
            {
                foreach (Item item in inv.AllItems)
                {
                    if (item?.HasTag("mobilebattery") == true)
                    {
                        if (item.Condition > 0.0f)
                        {
                            return item;
                        }
                    }
                }
            }

            return null;
        }

    }
}