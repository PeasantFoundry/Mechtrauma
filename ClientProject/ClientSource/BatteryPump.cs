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
    public partial class BatteryPump : Pump
    {

        public override void UpdateHUD(Character character, float deltaTime, Camera cam)
        {
            autoControlIndicator.Selected = IsAutoControlled;
            PowerButton.Enabled = isActiveLockTimer <= 0.0f;

            if (HasPower)
            {
                flickerTimer = 0;
                powerLight.Selected = IsActive;
            }
            else if (IsActive)
            {
                flickerTimer += deltaTime;
                float adjustedFlicker = UsingBattery ? 0.3f : flickerFrequency;
                if (flickerTimer > adjustedFlicker)
                {
                    flickerTimer = 0;
                    powerLight.Selected = !powerLight.Selected;
                }
            }
            else
            {
                flickerTimer = 0;
                powerLight.Selected = false;
            }
            pumpSpeedSlider.Enabled = pumpSpeedLockTimer <= 0.0f && IsActive;
            if (!PlayerInput.PrimaryMouseButtonHeld())
            {
                float pumpSpeedScroll = (FlowPercentage + 100.0f) / 200.0f;
                if (Math.Abs(pumpSpeedScroll - pumpSpeedSlider.BarScroll) > 0.01f)
                {
                    pumpSpeedSlider.BarScroll = pumpSpeedScroll;
                }
            }
        }
    }
}