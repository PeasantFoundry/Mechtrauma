using System;
using Barotrauma;
using Barotrauma.Networking;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Barotrauma.Items.Components;
using System.Linq;
 
namespace Mechtrauma {
    partial class Mechtrauma: ACsMod {
        private void changePowerRules() {
            // Changes the power connections limits to create steam and kinetic grids as well as the power grid.
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("ValidPowerConnection", BindingFlags.Static | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                args.Add("PreventExecution", true);

                Connection conn1 = (Connection)args["conn1"];
                Connection conn2 = (Connection)args["conn2"];

                // Don't connect devices that aren't on the power pin  or are broken
                if (!conn1.IsPower || !conn2.IsPower || conn1.Item.Condition <= 0.0f || conn2.Item.Condition <= 0.0f ||
                 conn1.Item.HasTag("disconnected") || conn2.Item.HasTag("disconnected")) {
                    return false;
                } 

                if (conn1.Name.StartsWith("steam") || conn2.Name.StartsWith("steam")) {
                    return conn1.Name.StartsWith("steam") && conn2.Name.StartsWith("steam") && (
                        conn1.IsOutput != conn2.IsOutput || 
                        conn1.Name == "steam" || 
                        conn2.Name == "steam" ||
                        conn1.Item.HasTag("steamjb") ||
                        conn2.Item.HasTag("steamjb")
                    );
                } else if (conn1.Name.StartsWith("kinetic") || conn2.Name.StartsWith("kinetic")) {
                    return conn1.Name.StartsWith("kinetic") && conn2.Name.StartsWith("kinetic") && (
                        conn1.IsOutput != conn2.IsOutput || 
                        conn1.Name == "kinetic" || 
                        conn2.Name == "kinetic" ||
                        conn1.Item.HasTag("kineticjb") ||
                        conn2.Item.HasTag("kineticjb")
                    );
                }

                // Prevent the original method from running
                args.Add("PreventExecution", false);
                return args;
            }, LuaCsHook.HookMethodType.Before, this);
 
            PropertyInfo isPowerField = typeof(Barotrauma.Items.Components.Connection).GetProperty("IsPower", BindingFlags.Instance | BindingFlags.Public);

            // Change the item connection loading to allow for steam and kinetic networks
            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Connection", 
            typeof(Barotrauma.Items.Components.Connection).GetConstructor(new[] { typeof(ContentXElement), typeof(ConnectionPanel), typeof(IdRemap) }),
            (object self, Dictionary<string, object> args) => {
                switch(((Barotrauma.Items.Components.Connection)self).Name) {
                    case "steam":
                    case "steam_out":
                    case "steam_in":
                        isPowerField.SetValue(self, true);
                        break;
                    case "kinetic":
                    case "kinetic_out":
                    case "kinetic_in":
                        isPowerField.SetValue(self, true);
                        break;
                }

                return args;
            }, LuaCsHook.HookMethodType.After, this);

            FieldInfo powerOutField = typeof(Barotrauma.Items.Components.Powered).GetField("powerOut", BindingFlags.Instance | BindingFlags.NonPublic);
            FieldInfo powerInField = typeof(Barotrauma.Items.Components.Powered).GetField("powerIn", BindingFlags.Instance | BindingFlags.NonPublic);
            FieldInfo itemField = typeof(Barotrauma.Items.Components.Powered).GetField("item", BindingFlags.Instance | BindingFlags.NonPublic);

            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Powered", 
            typeof(Barotrauma.Items.Components.Powered).GetMethod("OnItemLoaded", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                Item item = (self as Barotrauma.Items.Components.Powered).Item;

                if (item.Connections == null) { return args; }
                foreach (Connection c in item.Connections)
                {
                    if (!c.IsPower) { continue; }
                    switch (c.Name) {
                        case "steam_out":
                        case "kinetic_out":
                            powerOutField.SetValue(self, c);
                            break;
                        case "kinetic_in":
                        case "steam_in":
                            powerInField.SetValue(self, c);
                            break;
                        case "steam":
                        case "kinetic":
                            if (c.IsOutput) {
                                powerOutField.SetValue(self, c);
                            } else {
                                powerInField.SetValue(self, c);
                            }
                            break;
                    }
                }

                return args;
            }, LuaCsHook.HookMethodType.After, this);

            // Remove the power_in pin from the relay check as it causes an uncessary warning that doesn't affect it's functionality
            FieldInfo relayDictField = typeof(Barotrauma.Items.Components.RelayComponent).GetField("connectionPairs", BindingFlags.Static | BindingFlags.NonPublic);
            Dictionary<string, string> relayDict = relayDictField.GetValue(null) as Dictionary<string, string>;
            relayDict.Remove("power_in");
        }

        // Change the connection gui to show the steam and kinetic networks
        private void changeConnectionGUI() {
            FieldInfo spriteField = typeof(Barotrauma.Items.Components.Connection).GetField("connectionSprite", BindingFlags.Static | BindingFlags.NonPublic);

            GameMain.LuaCs.Hook.HookMethod("Barotrauma.Items.Components.Connection", 
                typeof(Barotrauma.Items.Components.Connection).GetMethod("DrawConnection", BindingFlags.Instance | BindingFlags.NonPublic),
                (Object self, Dictionary<string, object> args) => {
                    Barotrauma.Items.Components.Connection myself = (Barotrauma.Items.Components.Connection)self;
                    
                    SpriteBatch spriteBatch = args["spriteBatch"] as SpriteBatch;
                    ConnectionPanel panel = args["panel"] as ConnectionPanel;
                    Vector2 position = (Vector2)args["position"];
                    Vector2 labelPos = (Vector2)args["labelPos"];
                    Vector2 scale = (Vector2)args["scale"];

                    string text = myself.DisplayName.Value.ToUpperInvariant();

                    //nasty
                    if (GUIStyle.GetComponentStyle("ConnectionPanelLabel")?.Sprites.Values.First().First() is UISprite labelSprite)
                    {
                        Vector2 textSize = GUIStyle.SmallFont.MeasureString(text);
                        Rectangle labelArea = new Rectangle(labelPos.ToPoint(), textSize.ToPoint());
                        labelArea.Inflate(10 * scale.X, 3 * scale.Y);

                        Color colour = Color.SteelBlue;
                        if (myself.Name.StartsWith("steam")) {
                            colour = Color.DeepSkyBlue;
                        } else if (myself.Name.StartsWith("kinetic")) {
                            colour = Color.SaddleBrown;
                        } else if (myself.IsPower) {
                            colour = GUIStyle.Red;
                        }

                        labelSprite.Draw(spriteBatch, labelArea, colour);
                    }

                    GUI.DrawString(spriteBatch, labelPos + Vector2.UnitY, text, Color.Black * 0.8f, font: GUIStyle.SmallFont);
                    GUI.DrawString(spriteBatch, labelPos, text, GUIStyle.TextColorBright, font: GUIStyle.SmallFont);

                    Sprite connectionSprite = spriteField.GetValue(self) as Sprite;
                    float connectorSpriteScale = (35.0f / connectionSprite.SourceRect.Width) * panel.Scale;
                    connectionSprite.Draw(spriteBatch, position, scale: connectorSpriteScale);

                    // Prevent the original method from running
                    args.Add("PreventExecution", true);
                    return args;
                }, LuaCsHook.HookMethodType.Before, this);
        }
    }
}