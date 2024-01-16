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
    public partial class EngineBlock : ItemComponent
    {
        public EngineBlock(Item item, ContentXElement element) : base(item, element)
        {

        }
        // Engine fields 

        [Editable, Serialize(0.0f, IsPropertySaveable.Yes, description: "Maximum Operating Temperature.", alwaysUseInstanceValues: true)]
        public float RatedHP // combination cylinder displacement (block), number of cylinders
        {
            get => ratedHP;
            set => ratedHP = value;
        }
        private float ratedHP;

        public string FuelClass = "Diesel";
        
        public float CylinderHeadIndex = 0; // default location
        public float CrankAssemblyIndex = 1;
        

    }
}