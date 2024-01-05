using Barotrauma;
using Barotrauma.Extensions;
using Barotrauma.Networking;
using HarmonyLib;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Mechtrauma;

public partial class AdvancedTerminal : IClientSerializable, IServerSerializable
{

    #region VARS

    /// <summary>
    /// Contains all elements of the terminal message box and input box UI.
    /// </summary>
    protected GUILayoutGroup? TerminalLayoutGroup { get; set; }
    /// <summary>
    /// Crates spacing at the top of the message history box. 
    /// </summary>
    protected GUIFrame? TopPaddingBox { get; set; }
    /// <summary>
    /// Holds the GUITextBlocks containing historical messages.
    /// </summary>
    protected GUIListBox? MessageHistoryBox { get; set; }
    /// <summary>
    /// Fills space above the message box to force messages to display at the bottom first and then rise as there's more history to show.
    /// </summary>
    protected GUITextBlock? FillerBlock { get; set; }
    protected GUIFrame? HorizontalLine { get; set; }
    /// <summary>
    /// Player typing box.
    /// </summary>
    protected GUITextBox? InputBox { get; set; }
    /// <summary>
    /// Holds the skin sprite of the terminal (optional).
    /// </summary>
    protected GUICustomComponent? OuterSpriteGUI { get; set; }

    /// <summary>
    /// Only used if the intention is to not use the item.GuiFrame instance as the master parent.
    /// </summary>
    protected GUIFrame? AlternateGUIFrame { get; set; }
    
    /// <summary>
    /// Allows for a sprite to be rendered behind the terminal. Intended for use with skinned terminal designs.
    /// </summary>
    protected Sprite? OuterSprite { get; set; }
    /// <summary>
    /// Relative offset for the skin sprite.
    /// </summary>
    protected Vector2 OuterSpriteOffset { get; set; }
    /// <summary>
    /// Relative size of the skin sprite.
    /// </summary>
    protected Vector2 OuterSpriteSize { get; set; }
    /// <summary>
    /// Absolute offset of the sprite render.
    /// </summary>
    protected Vector2 OuterSpriteRenderPos { get; set; }

    /// <summary>
    /// Multiplier for the internal margin in the GUI Frame.
    /// </summary>
    public float MessageAreaMargin { get; protected set; }
    /// <summary>
    /// Whether or not the input box should be rendered.
    /// </summary>
    public bool ShowInputBox { get; protected set; }
    /// <summary>
    /// Relative vertical size of the message history box.
    /// </summary>
    public Vector2 MessageHistoryBoxSize { get; protected set; }
    /// <summary>
    /// Relative vertical size of the message history box
    /// </summary>
    public Vector2 MessageInputBoxSize { get; protected set; }
    /// <summary>
    /// Spacing between elements in the UI Container.
    /// </summary>
    public float LayoutRelativeSpacing { get; protected set; }
    /// <summary>
    /// The font to be used for terminal text. Value should be one of the static fonts declared in GUIStyle.
    /// </summary>
    public GUIFont? MessageFont { get; protected set; }
    /// <summary>
    /// Whether or not lines that are longer than the width of the console message area get wrapped to a new line.
    /// </summary>
    public bool LineWrap { get; protected set; }
    /// <summary>
    /// Whether or not the input box gets focused upon opening the tablet.
    /// </summary>
    public bool ShouldSelectInputBox { get; protected set; }
    /// <summary>
    /// The vertical padding at the top of the terminal windows for the console message history area.
    /// </summary>
    public float TopPadding { get; protected set; }
    
    /// <summary>
    /// Render scale of the skin sprite.
    /// </summary>
    public float OuterSpriteLinearScale { get; protected set; }
    
    /// <summary>
    /// Relative size of the terminal message and input area. Affected by GuiFrame and skin sprite sizes.
    /// </summary>
    public Vector2 TerminalSize { get; protected set; }
    
    /// <summary>
    /// Relative offset of the terminal history and message layout compared to the master GUIFrame or outer skin. 
    /// </summary>
    public Vector2 MessageAreaOffset { get; protected set; }
    
    /// <summary>
    /// Color of the master GUIFrame.
    /// </summary>
    public Color? TerminalFrameColor { get; protected set; }
    /// <summary>
    /// Whether or not the message history box should stretch to cover all remaining area of the GUILayout.
    /// Causes some alignment artifacts, should be kept off unless needed. 
    /// </summary>
    public bool MessageLayoutStretch { get; protected set; }
    
    
    public bool UseDesignScale { get; protected set; }
    
    /// <summary>
    /// The render ratio (width / height) that the tablet was designed at. Used to adjust vanilla GUI so it fits the
    /// sprite texture at different resolutions. Default is 1920/1080.
    /// </summary>
    public float DesignScale { get; protected set; }

    private bool _shouldSelectInputBox = true;
    private bool _clearOperationRequested;

    #endregion
    partial void InitializeXml(ContentXElement? element)
    {
        if (element is null)
        {
            ModUtils.Logging.PrintError($"AdvancedTerminal::InitializeXml() | Content xml is null!");
            return;
        }
        
        LineWrap = element.GetAttributeBool("LineWrap", true);
        ShouldSelectInputBox = element.GetAttributeBool("ShouldSelectInputBox", true);
        ReadOnly = element.GetAttributeBool("ReadOnly", false);
        _shouldSelectInputBox = ShouldSelectInputBox;
        
        if (element.GetChildElement("GuiFrame") is { } guiFrameElement)
        {
            TerminalFrameColor = guiFrameElement.GetAttributeColor("Color", Color.TransparentBlack);
            if (TerminalFrameColor == Color.TransparentBlack)
                TerminalFrameColor = null;
        }

        if (element.GetChildElement("MessageAreaGui") is { } msgAreaElement)
        {
            MessageAreaMargin = msgAreaElement.GetAttributeFloat("Margin", 0.15f);
            MessageAreaOffset = msgAreaElement.GetAttributeVector2("Offset", Vector2.Zero);
            TopPadding = msgAreaElement.GetAttributeFloat("TopPadding", 0.04f);
            MessageHistoryBoxSize = msgAreaElement.GetAttributeVector2("HistoryBoxSize", new Vector2(1.0f,0.8f));
            MessageInputBoxSize = msgAreaElement.GetAttributeVector2("InputBoxSize", new Vector2(1.0f, 0.1f));
            LayoutRelativeSpacing = msgAreaElement.GetAttributeFloat("RelativeSpacing", 0.02f);
            TerminalSize = msgAreaElement.GetAttributeVector2("RelativeSize", Vector2.One);
            ShowInputBox = msgAreaElement.GetAttributeBool("ShowInputBox", true);
            TextColor = msgAreaElement.GetAttributeColor("TextColor", Color.Green);
            UseDesignScale = msgAreaElement.GetAttributeBool("UseDesignScale", false);
            DesignScale = msgAreaElement.GetAttributeFloat("DesignScale", 1920f / 1080f);
            
            // parse font name
            string fontName = msgAreaElement.GetAttributeString("MessageFont", "Font");
            try
            {
                MessageFont = AccessTools.DeclaredField(fontName).GetValue(null) as GUIFont ?? GUIStyle.Font;
            }
            catch
            {
                MessageFont = GUIStyle.Font;
            }
        }
        
        if (element.GetChildElement("OuterSprite") is { } e)
        {
            OuterSprite = new Sprite(e.GetChildElement("Sprite"));
            OuterSpriteOffset = e.GetAttributeVector2("Offset", Vector2.Zero);
            OuterSpriteSize = e.GetAttributeVector2("Size", Vector2.One);
            OuterSpriteRenderPos = e.GetAttributeVector2("RenderPos", Vector2.Zero);
            OuterSpriteLinearScale = e.GetAttributeFloat("Scale", 1.0f);
        }
    }

    protected virtual void DrawOuterSprite(SpriteBatch spriteBatch, GUICustomComponent component)
    {
        // scale tablet based on design resolution
        float scaling = OuterSpriteLinearScale * GUI.Scale;
        OuterSprite?.Draw(spriteBatch, 
            new Vector2(component.RectTransform.Rect.X, component.RectTransform.Rect.Y), scale: scaling);
    }

    protected virtual void InitializeGUI()
    {
        var tgtGuiFrame = AlternateGUIFrame ?? GuiFrame;
        var tgtRectTransform = tgtGuiFrame.RectTransform;
        
        // render ratio only causes issues if under the design scale
        if (UseDesignScale && GUI.HorizontalAspectRatio < DesignScale - 0.001f)
        {
            var y = GUI.VerticalAspectRatio;
            var size = tgtGuiFrame.RectTransform.RelativeSize;
            size.X *= GUI.HorizontalAspectRatio / DesignScale;
        }
        
        if (TerminalFrameColor is not null)
        {
            tgtGuiFrame.Color = TerminalFrameColor.Value;
        }
        
        if (OuterSprite is not null)
        {
            // make the sprite the parent to we render our terminal on top of it.
            OuterSpriteGUI = new GUICustomComponent(new RectTransform(OuterSpriteSize, tgtGuiFrame.RectTransform, anchor: Anchor.TopCenter)
                {
                    RelativeOffset = OuterSpriteOffset
                },
                DrawOuterSprite, null);

            tgtRectTransform = OuterSpriteGUI.RectTransform;
        }

        TerminalLayoutGroup = new GUILayoutGroup(
            new RectTransform(TerminalSize,
                tgtRectTransform,
                anchor: Anchor.TopLeft)
            {
                AbsoluteOffset = GUIStyle.ItemFrameMargin.Multiply(MessageAreaMargin),
                RelativeOffset = MessageAreaOffset
            })
        {
            ChildAnchor = Anchor.TopCenter,
            RelativeSpacing = LayoutRelativeSpacing,
            Stretch = MessageLayoutStretch
        };
        
        TopPaddingBox =
            new GUIFrame(new RectTransform(new Vector2(1f, TopPadding), TerminalLayoutGroup.RectTransform), color: Color.Transparent);
        
        MessageHistoryBox = new GUIListBox(new RectTransform(
                MessageHistoryBoxSize,
                TerminalLayoutGroup.RectTransform),
            style: null)
        {
            AutoHideScrollBar = this.AutoHideScrollbar
        };

        FillerBlock = new GUITextBlock(
            new RectTransform(new Vector2(1f, 1f), MessageHistoryBox.Content.RectTransform, Anchor.TopCenter),
            string.Empty)
        {
            CanBeFocused = false
        };
        
        if (ShowInputBox)
        {
            HorizontalLine =
                new GUIFrame(new RectTransform(new Vector2(1f, 0.01f), TerminalLayoutGroup.RectTransform), 
                    style: "HorizontalLine");

            InputBox = new GUITextBox(
                new RectTransform(MessageInputBoxSize, TerminalLayoutGroup.RectTransform, Anchor.TopCenter),
                textColor: TextColor)
            {
                MaxTextLength = MaxLineChars,
                OverflowClip = true,
                OnEnterPressed = ((box, text) =>
                {
                    SendMessage(box.Text, TextColor);
                    GameMain.LuaCs.Hook.Call(EVENT_ONNEWPLAYERMESSAGE, this, box.Text, TextColor);
                    box.Text = string.Empty;
                    return true;
                })
            };
        }
        
        TerminalLayoutGroup.Recalculate();
    }

    private partial void SendMessageLocal(string text, Color color)
    {
        MessagesHistory.Add(new AdvTerminalMsg(text, color));
        TrimHistory(0);

        if (MessageHistoryBox is null)
            return;
        
        GUITextBlock newMessageBlock = new GUITextBlock(
            new RectTransform(new Vector2(1f, 0f), MessageHistoryBox.Content.RectTransform, Anchor.TopCenter),
            $"{LineStartSymbol ?? ""} {TextManager.Get(text).Fallback(text)}",
            textColor: color, wrap: LineWrap, font: MessageFont)
        {
            CanBeFocused = false
        };

        // space adjust
        if (FillerBlock is { })
        {
            float yDiff = FillerBlock.RectTransform.RelativeSize.Y - newMessageBlock.RectTransform.RelativeSize.Y;
            // move it
            if (yDiff > 0)
            { 
                FillerBlock.RectTransform.RelativeSize = new Vector2(1f, yDiff);
            }
            else
            {
                FillerBlock.RectTransform.RelativeSize = new Vector2(1f, 0f);
            }
        }
        
        MessageHistoryBox.RecalculateChildren();
        MessageHistoryBox.UpdateScrollBarSize();

        if (AutoScrollToBottom)
        {
            MessageHistoryBox.ScrollBar.BarScrollValue = 1f;
        }
        
        GameMain.LuaCs.Hook.Call(EVENT_ONNEWMESSAGE, this, text, color);
    }

    public override bool Select(Character character)
    {
        _shouldSelectInputBox = ShouldSelectInputBox;
        return base.Select(character);
    }

    public override void AddToGUIUpdateList(int order = 0)
    {
        base.AddToGUIUpdateList(order);
        if (InputBox is not null && _shouldSelectInputBox && ShowInputBox && !ReadOnly)
        {
            InputBox.Select();
            _shouldSelectInputBox = false;
        }
    }

    private partial void TrimHistory(int excess)
    {
        int maxLines = Math.Max(1, MaxLines - excess);
        while (MessagesHistory.Count > maxLines)
        {
            MessagesHistory.RemoveAt(0);    // trim oldest
        }

        if (MessageHistoryBox is null)
            return;

        ImmutableList<GUIComponent> messages = MessageHistoryBox.Content.Children
            .Where(c => c != FillerBlock).ToImmutableList();

        if (messages.Count < 1)
            return;
        
        foreach (var msg in messages)
        {
            if (MessageHistoryBox.Content.CountChildren <= maxLines)
                break;
            MessageHistoryBox.RemoveChild(msg);
        }
    }

    public partial void ClearHistory()
    {
        ClearHistoryLocal();
     
        if (GameMain.NetworkMember is null)
            return;
        
        // server-request clear
        _clearOperationRequested = true;
        item.CreateClientEvent(this);
    }

    private partial void ClearHistoryLocal()
    {
        MessagesHistory.Clear();
        ToProcess.Clear();

        if (MessageHistoryBox is null)
            return;
        
        ImmutableList<GUIComponent> messages = MessageHistoryBox.Content.Children
            .Where(c => c != FillerBlock).ToImmutableList();

        if (messages.Count < 1)
            return;
        
        foreach (var msg in messages)
        {
            MessageHistoryBox.RemoveChild(msg);
        }
    }

    public override partial void OnItemLoaded()
    {
        base.OnItemLoaded();
        InitializeGUI();
    }

    public partial void SendMessage(string text, Color color) => SendMessage(text, color, false);

    public partial void SendMessage(string text, Color color, bool overrideReadonly)
    {
        if (ReadOnly && !overrideReadonly)
            return;
        
        // single player
        if (GameMain.NetworkMember is null)
        {
            SendMessageLocal(text, color);
        }
        // multiplayer
        else
        {
            ToProcess.Enqueue(new AdvTerminalMsg(text, color));
            item.CreateClientEvent(this);
        }
    }

    public void ClientEventRead(IReadMessage msg, float sendingTime)
    {
        // Notes for networking:
        // event code : 0=message, 1=synchronize(clear history + message) as byte
        // message format: [ event-code | message count=ushort | array:<Message,Color=RGBA 8bit> ]
        byte evtCode = msg.ReadByte();
        switch (evtCode)
        {
            case 0:
                break;
            case 1: 
                ClearHistoryLocal();  // clear then process messages
                break;
        }

        ushort msgCount = msg.ReadUInt16();
        for (int i = 0; i < msgCount; i++)
        {
            var text = msg.ReadString();
            var color = msg.ReadColorR8G8B8A8();
            SendMessageLocal(text, color);
        }
    }
    
#pragma warning disable CS8625
    public void ClientEventWrite(IWriteMessage msg, NetEntityEvent.IData extraData = null)
#pragma warning restore CS8625
    {
        // event code : 0=message, 1=synchronize(clear history + message), 2=deletehistory as byte
        if (_clearOperationRequested)
            msg.WriteByte(2);   // clear and sync
        else
            msg.WriteByte(0);   //normal

        msg.WriteUInt16((ushort)ToProcess.Count); // message count
        while (ToProcess.Count > 0) // messages
        {
            var terminalMsg = ToProcess.Dequeue();
            msg.WriteString(terminalMsg.Text);
            msg.WriteColorR8G8B8A8(terminalMsg.Color);
        }
    }

}