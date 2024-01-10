using Barotrauma.Networking;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Mechtrauma
{
    public partial class Thermal : IClientSerializable, IServerSerializable
    {
        public void ServerEventRead(IReadMessage msg, Client c)
        {
            //throw new NotImplementedException();
        }

        public void ServerEventWrite(IWriteMessage msg, Client c, NetEntityEvent.IData extraData = null)
        {
            //throw new NotImplementedException();
        }
    }
}
