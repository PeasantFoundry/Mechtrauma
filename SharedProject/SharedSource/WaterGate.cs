/***
Water gate that is needed to enable central pumps by giving them an external access port
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
    public partial class WaterGate : Powered {

        public float MaxFlow { get; set; } = 100.0f;

        [Serialize(false, IsPropertySaveable.Yes, alwaysUseInstanceValues: true)]
        public bool IsInfected { get; set; }

        partial void InitProjSpecific(ContentXElement element);

        partial void UpdateProjSpecific(float deltaTime);

        public WaterGate(Item item, ContentXElement element) : base(item, element) 
        {
            IsActive = true;
        }

        public override void Update(float deltaTime, Camera cam)
        {
            // Place holder
        }

        /// <summary>
        /// Only move water if exposed to the outside
        /// </summary>
        public override float GetCurrentPowerConsumption(Connection connection)
        {
            ItemInventory inv = item.OwnInventory;
            bool isBlocked = false;
            if (inv != null)
            {
                // Get condition of the first item in the JB inventory
                Item? invItem = inv.GetItemAt(0);
                float itemCond = invItem?.Condition ?? 0.0f;
                isBlocked = itemCond > 0.0f;
            }

            //There shouldn't be other power connections to this
            //Only work if placed outside of the sub or in a hull exposed to lethal pressure
            // TODO: Figure out why IsActive is false for water_pump_gate
            if (connection == powerOut && !isBlocked && (item.CurrentHull == null || item.CurrentHull.LethalPressure > 0.1f))
            {
                return -1.0f;
            }

            return 0;
        }

        public override PowerRange MinMaxPowerOut(Connection connection, float load = 0)
        {
            if (connection == powerOut)
            {
                return new PowerRange(0, MaxFlow);
            }
            return PowerRange.Zero;
        }

        //Output the water
        public override float GetConnectionPowerOut(Connection connection, float power, PowerRange minMaxPower, float load)
        {
            if (connection == powerOut)
            {
                return MaxFlow;
            }
            return 0.0f;
        }

    }
}