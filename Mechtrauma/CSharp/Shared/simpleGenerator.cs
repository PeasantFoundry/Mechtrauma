/***
Simple generator component for Mechtrauma that allows for configurable power output and tolerance.
Using negative 'PowerConsumption' variable to provide power to the grid. While positive to add a load.
And the 'PowerTolerance' variable to allow for snapping to the grid demand.
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
    class SimpleGenerator : Powered {

        public float PowerTolerance {
            get => powerTolerance;
            set => powerTolerance = MathHelper.Clamp(value, 0.0f, 1.0f);
        }
        private float powerTolerance = 0.0f;

        [Editable, Serialize(0.0f, IsPropertySaveable.Yes, description: "Configurable Maximum power output of the device", alwaysUseInstanceValues: true)]
        public float MaxPowerOut {
            get => maxPowerOut;
            set => maxPowerOut = value;
        }
        private float maxPowerOut = 0.0f;

        public SimpleGenerator(Item item, ContentXElement element) : base(item, element) {
            IsActive = true;
            PowerTolerance = 0.0f;
        }

        public Connection PowerOut {get=>powerOut;}

        public float GridLoad {
            get {
                if (powerOut == null || powerOut.Grid == null) {
                    return 0.0f;
                }
                
                return powerOut.Grid.Load;
            }
        }

        public override float GetCurrentPowerConsumption(Connection connection) {
            if (connection == powerIn || !IsActive) {
                return 0.0f;
            }

            return (PowerConsumption >= 0 ? PowerConsumption : -1.0f);
        }

        // Calculate the min and max power output of the device for the given tolerance
        public override PowerRange MinMaxPowerOut(Connection connection, float load = 0) {
            if (connection == powerOut) {
                float minOut = -PowerConsumption * (1 - PowerTolerance);
                float maxOut = -PowerConsumption * (1 + PowerTolerance);
                return new PowerRange(minOut, maxOut, MaxPowerOut);
            }
            return PowerRange.Zero;
        }

        // Calculate power output alongside other simple generators in the same network to snap within their tolerances
        public override float GetConnectionPowerOut(Connection connection, float power, PowerRange minMaxPower, float load) {
            if (connection == powerOut && minMaxPower.Max > 0) {
                PowerRange myRange = MinMaxPowerOut(connection, load);

                float ratio = MathHelper.Max((load - power - minMaxPower.Min) / (minMaxPower.Max - minMaxPower.Min), 0);
                if (float.IsInfinity(ratio))
                {
                    ratio = 0;
                }

                return MathHelper.Clamp(ratio * (myRange.Max - myRange.Min) + myRange.Min, myRange.Min, myRange.Max);
            }
            return 0.0f;
        }

    }
}