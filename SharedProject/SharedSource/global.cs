global using System;
global using System.Collections;
global using System.Collections.Generic;
global using System.Collections.Concurrent;
global using System.Collections.Immutable;
global using System.Reflection;
global using System.Reflection.Emit;
global using System.Runtime.CompilerServices;
global using System.Linq;
global using System.Linq.Expressions;
global using ModdingToolkit;

/***
 * This file exists to contain Metadata References that are normally added automatically by MSBuild in .NET 5+
 * that are not included in LuaCsForBarotrauma's Metadata References at compile.
 * To avoid namespace conflicts, only .NET Base Class Libraries should be referenced here.
 */

[assembly: IgnoresAccessChecksTo("Barotrauma")]
[assembly: IgnoresAccessChecksTo("DedicatedServer")]

namespace Mechtrauma;
