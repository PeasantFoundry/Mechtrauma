using Barotrauma;
using Barotrauma.Items.Components;
using System;
using System.Collections.Generic;
using System.Text;

namespace Mechtrauma
{
    public class MTLight : LightComponent
    {
        [Serialize("", IsPropertySaveable.No)]
        public string Token { get; set; } // 

        public MTLight(Item item, ContentXElement element) : base(item, element)
        {

        }
    }
}
