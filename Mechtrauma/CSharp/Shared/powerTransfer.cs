/***
Modifies power containers so their output can be turned off
***/
using System;
using Barotrauma;
using Barotrauma.Networking;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Barotrauma.Items.Components;
using System.Linq;
 
namespace Mechtrauma {
    partial class Mechtrauma: ACsMod {

        // Changes powerTransfer components to add extra functionality if has item tag "fusedJB"
        private void modifyJunctionBoxes() {
            // Changes the power connections limits to create steam and kinetic grids as well as the power grid.
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.PowerTransfer", 
            typeof(Barotrauma.Items.Components.PowerTransfer).GetMethod("Update", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                PowerTransfer pt = (PowerTransfer)self;

                // Ignore if there are no connections
                if (pt.Item.Connections == null) {
                    return null;
                }

                if (pt.Item.HasTag("fusedJB")) {
                    // Check JB inventory
                    ItemInventory inv = pt.Item.OwnInventory;
                    if (inv != null) {

                        // Get condition of the first item in the JB inventory
                        Item? item = inv.GetItemAt(0);
                        float itemCond = item?.Condition ?? 0.0f;

                        // If disconnected but item condition is good then connect
                        if (pt.Item.HasTag("disconnected")) {
                            if (itemCond > 0.0f) {
                                pt.Item.ReplaceTag("disconnected", "");
                                flagConnections(pt.Item.Connections);
                            }
                        } else {
                            // If connected but item condition is bad then disconnect
                            if (itemCond <= 0.0f) {
                                pt.Item.AddTag("disconnected");
                                flagConnections(pt.Item.Connections);
                            }
                        }
                    }
                }

                return null;
            }, LuaCsHook.HookMethodType.Before, this);
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