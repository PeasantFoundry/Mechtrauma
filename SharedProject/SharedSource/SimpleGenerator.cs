/***
Simple generator component for Mechtrauma that allows for configurable power output and tolerance.
Using negative 'PowerConsumption' variable to provide power to the grid. While positive to add a load.
And the 'PowerTolerance' variable to allow for snapping to the grid demand.
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

namespace Mechtrauma
{
    public class SimpleGenerator : Powered {

        public override bool UpdateWhenInactive => true;

        public float Efficiency = 100.0f;
        public float Reliability = 100.0f;
        public float Accuracy = 100.0f;

        // diagnosticMode for the generator
        private bool diagnosticMode = false;
        [Editable, Serialize(false, IsPropertySaveable.Yes, description: "Diagnostic Mode.", alwaysUseInstanceValues: true)]     
        public bool DiagnosticMode{
            get => diagnosticMode;
            set => diagnosticMode = value;
        }


        private bool isOn = false;
        [Editable, Serialize(false, IsPropertySaveable.Yes, description: "Is the generator on.", alwaysUseInstanceValues: true)]
        public bool IsOn {
            get=>isOn;
            set=>isOn=value;
        }

        public float PowerTolerance {
            get => powerTolerance;
            set => powerTolerance = MathHelper.Clamp(value, 0.0f, 1.0f);
        }
        private float powerTolerance = 0.0f;
         
        // used by network events for clients to update power consumption
        [Editable, Serialize(0.0f, IsPropertySaveable.Yes, description: "Power to generate.", alwaysUseInstanceValues: true)]
        public float PowerToGenerate {
            get => powerToGenerate;
            set => powerToGenerate = value;
        }
        private float powerToGenerate = 0.0f;

        [Editable, Serialize(0.0f, IsPropertySaveable.Yes, description: "Configurable Maximum power output of the device.", alwaysUseInstanceValues: true)]
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
            if (connection == powerIn || !IsOn) {
                return 0.0f;
            }

            return -1f;
        }

        // Calculate the min and max power output of the device for the given tolerance
        public override PowerRange MinMaxPowerOut(Connection connection, float load = 0) {
            if (connection == powerOut) {
                PowerConsumption = -PowerToGenerate;

                if (PowerConsumption > 0)
                {
                    PowerConsumption = 0.0f;
                }

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
        
        public override void Update(float deltaTime, Camera cam)
        {
            
            if (IsOn) {
                base.Update(deltaTime, cam);
            }
            item.SendSignal(IsOn ? "1" : "0", "state_out");
            
        }
        
        public override void ReceiveSignal(Signal signal, Connection connection)
        {
            if (connection.Name == "toggle")
            {
                IsOn = !IsOn;
            }
            else if (connection.Name == "set_state")
            {
                IsOn = signal.value != "0";
            }
        }

    }
}