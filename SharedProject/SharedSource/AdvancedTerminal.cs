using System.Text;
using System.Xml.Linq;
using Barotrauma;
using Barotrauma.Items.Components;
using Microsoft.Xna.Framework;

namespace Mechtrauma;

public record AdvTerminalMsg(string Text, Color Color);

public partial class AdvancedTerminal : ItemComponent
{
    #region VARS
    
    //--- SYMBOLS
    public static readonly string EVENT_ONNEWMESSAGE = "Mechtrauma.AdvancedTerminal::NewMessage"; // args: (this, text, color)
    public static readonly string EVENT_ONNEWPLAYERMESSAGE = "Mechtrauma.AdvancedTerminal::NewPlayerMessage"; // args: (this, text, color)

    //--- CVARS
    
    public AdvancedTerminal(Item item, ContentXElement element) : base(item, element)
    {
        // ReSharper disable once VirtualMemberCallInConstructor
        IsActive = true;
        InitializeXml(element);
    }

    [Serialize(100, IsPropertySaveable.No, description: "Max line count.")]
    public int MaxLines { get; set; }
    
    [Serialize(255, IsPropertySaveable.No, description: "Max characters per line.")]
    public int MaxLineChars { get; set; }

    [Serialize(false, IsPropertySaveable.No)]
    public bool AutoHideScrollbar { get; set; }
    
    [Editable, Serialize("> ", IsPropertySaveable.Yes)]
    public string? LineStartSymbol { get; set; }
    
    [Editable, Serialize(false, IsPropertySaveable.Yes)]
    public bool ReadOnly { get; set; }
    
    [Serialize(true, IsPropertySaveable.No)]
    public bool AutoScrollToBottom { get; set; }

    public static readonly int MaxCharsPerLine = 255;
    
    public string ShowMessage
    {
        get => "";
        set => SendMessage(value, TextColor);
    }
    
    public Color TextColor { get; protected set; } = Color.Green;

    /// <summary>
    /// For use by Status Effects to send messages to the terminal. Name inherited from vanilla.
    /// </summary>
    public string OutputValue
    {
        get
        {
            if (MessagesHistory.Count > 0)
                return MessagesHistory[^1].Text;
            return string.Empty;
        }
        set
        {
            if (string.IsNullOrEmpty(value))
                return;
            SendMessage(value, TextColor);
        }
    }

    
    
    //--- INTERNAL VARS
    
    protected readonly List<AdvTerminalMsg> MessagesHistory = new();
    protected readonly Queue<AdvTerminalMsg> ToProcess = new(); // use this to handle sync events
    

    #endregion

    #region FUNCDEF

    partial void InitializeXml(ContentXElement? element);

    private partial void SendMessageLocal(string text, Color color);
    public override partial void OnItemLoaded();
    public partial void SendMessage(string text, Color color, bool overrideReadonly);
    public partial void SendMessage(string text, Color color);
    public partial void ClearHistory();
    private partial void ClearHistoryLocal();
    private partial void TrimHistory(int excess);
    public override XElement Save(XElement parentElement)
    {
        var componentElement = base.Save(parentElement);
        for (int i = 0; i < MessagesHistory.Count; i++)
        {
            var message = MessagesHistory[i];
            componentElement.Add($"msg{i}", message.Text);
            componentElement.Add($"color{i}", message.Color.ToStringHex());
        }

        return componentElement;
    }

    public override void Load(ContentXElement componentElement, bool usePrefabValues, IdRemap idRemap)
    {
        base.Load(componentElement, usePrefabValues, idRemap);
        // load messages, do not sync with the server or it becomes a network race condition, save file should be identical.
        for (int i = 0; i < MaxLines; i++)
        {
            string? message = componentElement.GetAttributeString($"msg{i}", null);
            if (message is null)
                break;  //we're done
            Color color = componentElement.GetAttributeColor($"color{i}", TextColor);
            SendMessageLocal(message, color);
        }
    }

    public override string ToString()
    {
        if (MessagesHistory.Count < 1)
            return "";
        StringBuilder builder = new();
        foreach (var msg in MessagesHistory)
        {
            builder.Append(msg.Text);
        }

        return builder.ToString();
    }

    public override void ReceiveSignal(Signal signal, Connection connection)
    {
        switch (connection.Name)
        {
            case "set_text": case "signal_in":
                if (string.IsNullOrEmpty(signal.value))
                    return;
                if (signal.value.Length > MaxLineChars)
                {
                    SendMessage(signal.value.Substring(0, MaxLineChars).Replace("\\n", "\n"), TextColor);
                    break;
                }
                SendMessage(signal.value.Replace("\\n", "\n"), TextColor);
                break;
            case "set_text_color":
                TextColor = XMLExtensions.ParseColor(signal.value, false);
                break;
            case "clear_text":
                if (signal.value != "0")
                    ClearHistory();
                break;
        }
    }

    #endregion

}