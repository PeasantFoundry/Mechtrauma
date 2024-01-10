using Barotrauma.Items.Components;
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
        public void ClientEventRead(IReadMessage msg, float sendingTime)
        {
            //throw new NotImplementedException();
        }

        public void ClientEventWrite(IWriteMessage msg, NetEntityEvent.IData extraData = null)
        {
            //throw new NotImplementedException();
        }
    }
}
