using ModdingToolkit;
using Barotrauma;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


[assembly: IgnoresAccessChecksTo("Barotrauma")]
[assembly: IgnoresAccessChecksTo("DedicatedServer")]
namespace Mechtrauma
{
    public partial class Plugin : IAssemblyPlugin
    {
        // Server-specific code
    }
}
