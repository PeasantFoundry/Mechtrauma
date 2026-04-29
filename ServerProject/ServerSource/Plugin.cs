using System.Runtime.CompilerServices;
using Barotrauma;
using Barotrauma.LuaCs;

[assembly: IgnoresAccessChecksTo("BarotraumaCore")]
[assembly: IgnoresAccessChecksTo("DedicatedServer")]

namespace Mechtrauma
{
    public partial class Plugin : IAssemblyPlugin
    {
        // Server-specific code
    }
}
