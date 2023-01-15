/***
Custom Junction box that checks for a fuse and will break connection if the fuse is broken
***/
using System;
using Barotrauma;
using Barotrauma.Networking;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using System.Linq;
using System.Xml.Linq;
using Barotrauma.Items.Components;

namespace Barotrauma.Items.Components 
{
    class FusedJB : PowerTransfer {
        public bool BrokenFuse { 
            get => brokenFuse; 
            set 
            { 
                // Only update if the value has changed
                if (value != brokenFuse) {
                    brokenFuse = value;
                    flagConnections(item.Connections);
                }
            }
        }

        private bool brokenFuse = false;

        public FusedJB(Item item, ContentXElement element) : base(item, element) {
            // call base constructor
        }

        // Update check fuse condition and update flag
        public override void Update(float deltaTime, Camera cam) {
            base.Update(deltaTime, cam);

            // Check JB inventory
            ItemInventory inv = item.OwnInventory;
            if (inv != null) {

                // Get condition of the first item in the JB inventory
                Item? invItem = inv.GetItemAt(0);
                float itemCond = invItem?.Condition ?? 0.0f;
                BrokenFuse = itemCond <= 0.0f;
            }
        }

        // Flag to the power grid that connections need to be updated (Important for the power grid cache to know)
        private void flagConnections(List<Connection> connections) {
            foreach (Connection c in connections)
                {
                    if (c.IsPower)
                    {
                        Powered.ChangedConnections.Add(c);
                        foreach (Connection conn in c.Recipients)
                        {
                            Powered.ChangedConnections.Add(conn);
                        }
                    }
                }
        }
    }
}