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


