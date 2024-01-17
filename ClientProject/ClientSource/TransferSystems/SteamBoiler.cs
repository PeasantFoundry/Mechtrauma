using Barotrauma.Networking;

namespace Mechtrauma.TransferSystems;

public partial class SteamBoiler : IClientSerializable, IServerSerializable
{
    public void ClientEventWrite(IWriteMessage msg, NetEntityEvent.IData extraData = null)
    {
        throw new NotImplementedException();
    }

    public void ClientEventRead(IReadMessage msg, float sendingTime)
    {
        throw new NotImplementedException();
    }
}