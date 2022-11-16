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

        // Change the power container to disable output if not active
        private void modifyJunctionBoxes() {
            // Changes the power connections limits to create steam and kinetic grids as well as the power grid.
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.PowerTransfer", 
            typeof(Barotrauma.Items.Components.PowerTransfer).GetMethod("Update", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                PowerTransfer pt = (PowerTransfer)self;
                if (pt.Item.Connections == null) {
                    return null;
                }

                if (pt.Item.HasTag("fusedJB")) {
                    ItemInventory inv = pt.Item.OwnInventory;
                    if (inv != null) {
                        Item? item = inv.GetItemAt(0);
                        float itemCond = item?.Condition ?? 0.0f;

                        if (pt.Item.HasTag("disconnected")) {
                            if (itemCond > 0.0f) {
                                pt.Item.ReplaceTag("disconnected", "");
                                flagConnections(pt.Item.Connections);
                            }
                        } else {
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