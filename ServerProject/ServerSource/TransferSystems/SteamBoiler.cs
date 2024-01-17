using Barotrauma.Networking;

namespace Mechtrauma.TransferSystems;

public partial class SteamBoiler : IClientSerializable, IServerSerializable
{
    public void ServerEventRead(IReadMessage msg, Client c)
    {
        throw new NotImplementedException();
    }

    public void ServerEventWrite(IWriteMessage msg, Client c, NetEntityEvent.IData extraData = null)
    {
        throw new NotImplementedException();
    }
}