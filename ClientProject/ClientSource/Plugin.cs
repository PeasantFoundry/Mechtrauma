using ModdingToolkit;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

[assembly: IgnoresAccessChecksTo("Barotrauma")]
namespace Mechtrauma
{
    public partial class Plugin : IAssemblyPlugin
    {
        void ClientInitialize()
        {
            changeConnectionGUI();
        }
    }
}
