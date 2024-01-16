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
            InitializeXml(element);
        }

        private void InitializeXml(ContentXElement? element)
        {
            if (element is null)
            {
                ModUtils.Logging.PrintError($"DieselEngine::InitializeXml() | Content xml is null!");
                return;
            }

            HorsePower = element.GetAttributeFloat("HorsePower", 3000f);
            if (element.GetChildElement("EngineBlock") is { } coolingElement)
            {
                HorsePower = coolingElement.GetAttributeFloat("HorsePower", 3000f);
            }
        }

        //EngineBlock
        public float HorsePower;

        // standard fields
        // public float Temperature = 60.0f; 60 is default temperature 

        [Serialize("> ", IsPropertySaveable.Yes)]
        public string? Generation { get; set; } // 3rd generation requires the new part functionality, 2nd gen are legacy generators 1st gen was the XML only generators.  
        
        [Serialize( -1, IsPropertySaveable.Yes)]
        public int EngineBlockLocation { get; set; } // index location for engine block
                                                      //public string Generation { get; set; } 

        public float RatedHP = 2000f; // default HP if there is no engine block
        public float MaxHP = 2000f; // calculated HP from parts and enhancements
        public float GeneratedHP = 0f; // HP generated this cycle

        public float CoolantVol = 0.0f; // CL
        public float CoolantCapacity = 6000.0f; // CL
        public float CoolantLevel = 0.0f; // %        
        public float CoolingAvailable = 0.0f; // BTU - change to CoolingCapacity
        public float OperatingTemperature = 200.0f; // F        
        public float CoolingCapacity = 150000.0f; // BTU - change to MaxCoolingCapacity
        public float CoolingNeeded = 0.0f; // BTU
        public float HeatGenerated = 0.0f; // BTU
        public float HeatSurplus = 0.0f; // BTU
        public string ExternalHeatExchanger; // BTU
        public bool IsRunning; // Ignition + Combustion


        [Editable, Serialize(false, IsPropertySaveable.Yes)]
        public bool DiagnosticMode { get; set; }

        [Editable, Serialize(false, IsPropertySaveable.Yes)]
        public bool ShowStatus { get; set; }
        [Editable, Serialize(false, IsPropertySaveable.Yes)]
        public bool ShowLevels { get; set; }
        [Editable, Serialize(false, IsPropertySaveable.Yes)]
        public bool ShowTemps { get; set; }

    }
}
