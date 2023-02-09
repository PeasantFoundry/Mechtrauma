/***
Modified power container that can be turned on and off
***/
using ModdingToolkit;

using System;
using Barotrauma;
using Barotrauma.Networking;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Barotrauma.Items.Components;
using System.Linq;

namespace Barotrauma.Items.Components 
{
    class ControllablePowerContainer : PowerContainer {

        [Editable, Serialize(true, IsPropertySaveable.Yes, description: "Turn the power container output on and off", alwaysUseInstanceValues: true)]
        public bool IsOn { 
            get => isOn; 
            set => isOn = value;
        }
        private bool isOn = true;

        public ControllablePowerContainer(Item item, ContentXElement element) : base(item, element) {
            // call base constructor
            isOn = true;
        }

        public override PowerRange MinMaxPowerOut(Connection connection, float load = 0) {
            // Return zero power if the output is off
            if (connection == powerOut && !isOn) {
                return PowerRange.Zero;
            } 
            return base.MinMaxPowerOut(connection, load);
        }

        // Add custom toggle and set state signals which can be used to turn the output on and off
        public override void ReceiveSignal(Signal signal, Connection connection)
        {
            if (item.Condition <= 0.0f || connection.IsPower) { return; }

            // Call base method to handle other signals
            base.ReceiveSignal(signal, connection);
            
            if (connection.Name == "toggle")
            {
                if (signal.value == "0") { return; }
                SetState(!IsOn, false);
            }
            else if (connection.Name == "set_state")
            {
                SetState(signal.value != "0", false);
            }
        }

        // SetState function to handle setting output state and relevant networking
        public void SetState(bool on, bool isNetworkMessage)
        {
#if CLIENT
            if (GameMain.Client != null && !isNetworkMessage) { return; }
#endif

#if SERVER
            if (on != IsOn && GameMain.Server != null)
            {
                item.CreateServerEvent(this);
            }
#endif

            IsOn = on;
        }

// Add isOn boolean to the server network event
#if SERVER
        public new void ServerEventWrite(IWriteMessage msg, Client c, NetEntityEvent.IData extraData = null)
        {
            base.ServerEventWrite(msg, c, extraData);
            msg.WriteBoolean(isOn);
        }
#endif

// Read isOn boolean from the client network event
#if CLIENT
        public new void ClientEventRead(IReadMessage msg, float sendingTime)
        {
            // Keep track of whether delayedCorrection will occur, so we don't read the msg
            bool delayedCorrection = correctionTimer > 0.0f;

            // Call base method to handle original network event
            base.ClientEventRead(msg, sendingTime);

            // Skip reading the msg if delayedCorrection will occur
            if (delayedCorrection) {
                return;
            }

            SetState(msg.ReadBoolean(), true);
        }
#endif
    }
}