using Barotrauma;
using Barotrauma.Networking;

namespace Mechtrauma;

public partial class PlayerLadderDetector : IServerSerializable
{
    public void ServerEventWrite(IWriteMessage msg, Client c, NetEntityEvent.IData extraData = null)
    {
        msg.WriteBoolean(IsOnLadder);
    }

    private partial void Synchronize()
    {
        item.CreateServerEvent(this);
        TriggerHooks();
    }
}