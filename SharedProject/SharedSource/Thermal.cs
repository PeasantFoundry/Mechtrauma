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
    public partial class Thermal : ItemComponent
    {
        public Thermal(Item item, ContentXElement element) : base(item, element)
        {

        }
        // standard fields
        public float Temperature = 60.0f; // 60 is default temperature 

        // need to track temperature change over time to calculate how quickly it has changed 
    }
}
