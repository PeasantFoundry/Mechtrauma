using Barotrauma;
using Barotrauma.Networking;

namespace Mechtrauma;

public partial class LuaNetEventDispatcher : IClientSerializable, IServerSerializable
{
    public void ClientEventWrite(IWriteMessage msg, NetEntityEvent.IData extraData = null)
    {
        //ModUtils.Logging.PrintMessage("CLIENT EVENT WRITE");
        GameMain.LuaCs.Hook.Call(Event_ClientWrite, this, msg, extraData);
    }

    public void ClientEventRead(IReadMessage msg, float sendingTime)
    {        
        GameMain.LuaCs.Hook.Call(Event_ClientRead, this, msg, sendingTime);
    }

    public virtual partial void SendEvent()
    {     
        if (GameMain.NetworkMember is null)
        {     
            return;
        }     
        item.CreateClientEvent(this);
    }
}