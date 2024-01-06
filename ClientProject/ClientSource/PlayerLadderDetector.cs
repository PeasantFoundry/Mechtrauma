using Barotrauma;
using Barotrauma.Networking;

namespace Mechtrauma;

public partial class PlayerLadderDetector : IServerSerializable
{
    public void ClientEventRead(IReadMessage msg, float sendingTime)
    {
        IsOnLadder = msg.ReadBoolean();
        TriggerHooks();
    }

    private partial void Synchronize()
    {
        TriggerHooks();
    }
}