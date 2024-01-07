using ModdingToolkit;

using System;
using Barotrauma;
using Barotrauma.Networking;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Barotrauma.Items.Components;
using System.Linq;
using System.Xml;

namespace Mechtrauma
{
    public partial class DieselEngine : ItemComponent
    {
        public DieselEngine(Item item, ContentXElement element) : base(item, element)
        {

        }
        // standard fields
        public float Temperature = 60.0f; // 60 is default temperature 

        public float CoolantVol = 0.0f; // CL
        public float CoolantCapacity = 8000.0f; // CL
        public float CoolantLevel = 0.0f; // %        
        public float CoolingAvailable = 0.0f; // BTU
        public float OperatingTemperature = 200.0f; // F        
        public float CoolingCapacity = 150000.0f; // BTU
        public float CoolingNeeded = 0.0f; // BTU
        public float HeatGenerated = 0.0f; // BTU
        public float HeatSurplus = 0.0f; // BTU


        // customizable fields (hopefully)
        public float DB1 = 100.0f;
        public float DB2 = 200.0f;
        public float DB3 = 300.0f;

        // JSON test. the idea is to convert lua tables to JSON and store them in component strings for persisting lua data between rounds. (harddrives items with diagnostic data, ships logs, etc)
        //public string jsonTest;

        /*** diagnosticMode for the generator
        private bool diagnosticMode = false;
        [Editable, Serialize(false, IsPropertySaveable.Yes, description: "Diagnostic Mode.", alwaysUseInstanceValues: true)]
        public bool DiagnosticMode
        {
            get => diagnosticMode;
            set => diagnosticMode = value;
        }
        ***/
    }
}