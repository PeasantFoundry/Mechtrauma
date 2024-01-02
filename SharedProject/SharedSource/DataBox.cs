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
    public class DataBox : ItemComponent
    {
        public DataBox(Item item, ContentXElement element) : base(item, element)
        {
  
        }

        public float DB1 = 100.0f;
        public float DB2 = 200.0f;
        public float DB3 = 300.0f;

        public string jsonTest;

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