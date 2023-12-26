using System.Xml.Linq;
using Barotrauma;
using Barotrauma.Networking;
using Microsoft.Xna.Framework;

namespace Mechtrauma;

public partial class AdvancedTerminal : IClientSerializable, IServerSerializable
{
    private bool _synchroRequestReceived = false;
    
    partial void InitializeXml(ContentXElement? element)
    {
        if (element is null)
        {
            ModUtils.Logging.PrintError($"AdvancedTerminal::InitializeXml() | Content xml is null!");
            return;
        }
        
        TextColor = element.GetAttributeColor("TextColor", Color.Green);
    }

    public partial void ClearHistory()
    {
        _synchroRequestReceived = true; // sync clients
        ClearHistoryLocal();
        item.CreateServerEvent(this);
    }
    
    private partial void TrimHistory(int excess)
    {
        int maxLines = Math.Max(0, MaxLines - excess);
        
        while (MessagesHistory.Count > maxLines)
        {
            MessagesHistory.RemoveAt(0);    // trim oldest
        }
    }

    private partial void ClearHistoryLocal()
    {
        MessagesHistory.Clear();
        ToProcess.Clear();
    }
    
    public partial void SendMessage(string text, Color color) => SendMessage(text, color, false);

    public partial void SendMessage(string text, Color color, bool overrideReadonly)
    {
        if (ReadOnly && !overrideReadonly)
            return;
        
        ToProcess.Enqueue(new AdvTerminalMsg(text, color));
        item.CreateServerEvent(this);
    }

    private partial void SendMessageLocal(string text, Color color)
    {
        MessagesHistory.Add(new AdvTerminalMsg(text, color));
        TrimHistory(0);
        item.SendSignal(text, "signal_out");
        MTEvents.Instance.SendEventLocal(EVENT_ONNEWMESSAGE, this, text, color);
    }

    public override partial void OnItemLoaded()
    {
        base.OnItemLoaded();
    }

    public void ServerEventRead(IReadMessage msg, Client c)
    {
        // Notes for networking:
        // event code : 0=message, 1=synchronize(clear history + message), 2=deletehistory as byte
        // message format: [ event-code | message count=ushort | array:<Message,Color=RGBA 8bit> ]
        byte evtCode = msg.ReadByte();
        switch (evtCode)
        {
            case 0:
                EnqueueIncomingMessages();
                break;
            case 1:
                _synchroRequestReceived = true;
                EnqueueIncomingMessages();
                break;
            case 2:
                ClearHistory();
                break;
        }

        void EnqueueIncomingMessages()
        {
            ushort msgCount = msg.ReadUInt16();
            for (int i = 0; i < msgCount; i++)
            {
                string text = msg.ReadString();
                Color color = msg.ReadColorR8G8B8A8();
                ToProcess.Enqueue(new AdvTerminalMsg(text, color));
            }
            item.CreateServerEvent(this);   
        }
    }

#pragma warning disable CS8625
    public void ServerEventWrite(IWriteMessage msg, Client c, NetEntityEvent.IData extraData = null)
#pragma warning restore CS8625
    {
        // trim history accounting for new messages
        TrimHistory(ToProcess.Count);
        
        // set evt code
        msg.WriteByte(_synchroRequestReceived ? (byte)1 : (byte)0);

        // set message count
        var msgCount = _synchroRequestReceived
            ? (ushort)(MessagesHistory.Count + ToProcess.Count)
            : (ushort)ToProcess.Count;
        msg.WriteUInt16(msgCount);

        if (msgCount < 1)
            return; // no messages to write
        
        // add messages
        if (_synchroRequestReceived)
        {
            _synchroRequestReceived = false;
            // add old messages first
            foreach (var terminalMsg in MessagesHistory)
            {
                msg.WriteString(terminalMsg.Text);
                msg.WriteColorR8G8B8A8(terminalMsg.Color);
            }
        }
        
        // process enqueued messages, add to local and send to clients
        while (ToProcess.Count > 0)
        {
            var terminalMsg = ToProcess.Dequeue();
            MessagesHistory.Add(terminalMsg);
            item.SendSignal(terminalMsg.Text, "signal_out");
            msg.WriteString(terminalMsg.Text);
            msg.WriteColorR8G8B8A8(terminalMsg.Color);
        }

    }
}