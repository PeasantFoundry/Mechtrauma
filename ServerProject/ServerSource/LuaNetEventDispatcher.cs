using Barotrauma;
using Barotrauma.Networking;

namespace Mechtrauma;

public partial class LuaNetEventDispatcher : IClientSerializable, IServerSerializable
{
    public void ServerEventRead(IReadMessage msg, Client c)
    {
        GameMain.LuaCs.Hook.Call(Event_ServerRead, msg, c);
    }

    public void ServerEventWrite(IWriteMessage msg, Client c, NetEntityEvent.IData extraData = null)
    {
        GameMain.LuaCs.Hook.Call(Event_ServerWrite, msg, c, extraData);
    }
    
    public virtual partial void SendEvent()
    {
        item.CreateServerEvent(this);
    }
}