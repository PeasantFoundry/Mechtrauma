using Barotrauma;

using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using MoonSharp.Interpreter;
using System.Text;
using Barotrauma.Extensions;
using Barotrauma.Items.Components;
using Barotrauma.LuaCs;
using Barotrauma.LuaCs.Compatibility;
using HarmonyLib;
using Microsoft.VisualBasic.CompilerServices;

namespace Mechtrauma
{
    public partial class Plugin : IAssemblyPlugin
    {
        
        public static Plugin? Instance { get; private set; }
        private ContentPackage? _selfPackage;
        public ContentPackage SelfPackage => _selfPackage ??= GetSelfContentPackage();

        public IConfigService ConfigService { get; set; }
        public Configuration Config;
        
        public Plugin()
        {
            Instance = this;
        }
        
        public void Initialize()
        {
            ModUtils.Logging.PrintMessage("Mechtrauma starting...");
            ChangePowerRules();
            Config = new Configuration(ConfigService, SelfPackage);
            InitUserData();
#if SERVER
            //GameMain.Server?.SendChatMessage("Started Mechtrauma");
#elif CLIENT
            //GameMain.Client?.SendChatMessage("Started Mechtrauma");
            ClientInitialize();
#endif
        }

        public void OnLoadCompleted()
        {
            
        }

        public void PreInitPatching()
        {

        }

        public ContentPackage GetSelfContentPackage() =>
            ContentPackageManager.EnabledPackages.Regular.First(p => p.Name.Trim().ToLowerInvariant().StartsWith("mechtrauma"));

        private void InitUserData()
        {
            UserData.RegisterType<Configuration>();
            UserData.RegisterType<Configuration.Settings_General>();
            UserData.RegisterType<Configuration.Settings_Advanced>();
            UserData.RegisterType<Configuration.Settings_Experimental>();
            UserData.RegisterType<AdvanceOxygenGenerator>();
            UserData.RegisterType<CentralPump>();
            UserData.RegisterType<ControllablePowerContainer>();
            UserData.RegisterType<FusedJB>();
            UserData.RegisterType<GridAbsorber>();
            UserData.RegisterType<MTBoiler>();
            UserData.RegisterType<SimpleGenerator>();
            UserData.RegisterType<DieselEngine>();
            UserData.RegisterType<EngineBlock>();
            UserData.RegisterType<Thermal>();
            UserData.RegisterType<MTLight>();
            UserData.RegisterType<MTC>();
            UserData.RegisterType<DataBox>();
            UserData.RegisterType<WaterDrain>();
            UserData.RegisterType<AdvancedTerminal>();
            UserData.RegisterType<AdvTerminalMsg>();
            UserData.RegisterType<LuaNetEventDispatcher>();

            UserData.RegisterType(typeof(MTUtils));

            // delay for lua scripts startup
            CoroutineManager.Invoke(() =>
            {
                LuaCsSetup.Instance.LuaScriptManagementService.InternalScript!.Globals["MTUtils"] = UserData.CreateStatic(typeof(MTUtils));
                LuaCsSetup.Instance.LuaScriptManagementService.InternalScript!.Globals["MTConfig"] = Config;
            });
        }

        private void UnloadUserData()
        {
            LuaCsSetup.Instance.LuaScriptManagementService.InternalScript?.Globals["MTConfig"] = null;
            LuaCsSetup.Instance.LuaScriptManagementService.InternalScript?.Globals["MTUtils"] = null;

            UserData.RegisterType(typeof(MTUtils));

            UserData.UnregisterType<Configuration.Settings_Experimental>();
            UserData.UnregisterType<Configuration.Settings_Advanced>();
            UserData.UnregisterType<Configuration.Settings_General>();
            UserData.UnregisterType<Configuration>();
            UserData.UnregisterType<AdvanceOxygenGenerator>();
            UserData.UnregisterType<CentralPump>();
            UserData.UnregisterType<ControllablePowerContainer>();
            UserData.UnregisterType<FusedJB>();
            UserData.UnregisterType<GridAbsorber>();
            UserData.UnregisterType<MTBoiler>();
            UserData.UnregisterType<SimpleGenerator>();
            UserData.UnregisterType<DieselEngine>();
            UserData.UnregisterType<EngineBlock>();
            UserData.UnregisterType<Thermal>();
            UserData.UnregisterType<MTLight>();
            UserData.UnregisterType<MTC>();
            UserData.UnregisterType<DataBox>();
            UserData.UnregisterType<WaterDrain>();
            UserData.UnregisterType<AdvancedTerminal>();
            UserData.UnregisterType<AdvTerminalMsg>();
            UserData.UnregisterType<LuaNetEventDispatcher>();
        }

        public void Dispose()
        {
            UnloadUserData();
#if SERVER
            // server-side code
#elif CLIENT
            Styles.Values.ForEach(s => s.UnloadFile());
            Styles.Clear();
#endif
        }

        List<string> ExtraPowerTypes = new List<string>() {
            "steam",
            "kinetic",
            "thermal",
            "waterGate",
            "water",
            "oxygen"
        };

        // Change the power connection rules to isolate the steam, power and kinetic networks.
        private void ChangePowerRules()
        {
            // Changes the power connections limits to create steam and kinetic grids as well as the power grid.
            LuaCsSetup.Instance.Hook.HookMethod("Barotrauma.Items.Components.Powered",
            typeof(Barotrauma.Items.Components.Powered).GetMethod("ValidPowerConnection", BindingFlags.Static | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {

                Connection conn1 = (Connection)args["conn1"];
                Connection conn2 = (Connection)args["conn2"];

                // Don't connect devices that aren't on the power pin  or are broken
                if (!conn1.IsPower || !conn2.IsPower || conn1.Item.Condition <= 0.0f || conn2.Item.Condition <= 0.0f ||
                 conn1.Item.HasTag("disconnected") || conn2.Item.HasTag("disconnected"))
                {
                    return false;
                }

                FusedJB device = conn1.Item.GetComponent<FusedJB>();
                if (device != null && device.BrokenFuse)
                {
                    return false;
                }

                device = conn2.Item.GetComponent<FusedJB>();
                if (device != null && device.BrokenFuse)
                {
                    return false;
                }

                // Check if its an extra power type connection, if so, only connect extra power type connections to each other
                foreach (string powerType in ExtraPowerTypes)
                {
                    if (conn1.Name.StartsWith(powerType) || conn2.Name.StartsWith(powerType))
                    {
                        return conn1.Name.StartsWith(powerType) && conn2.Name.StartsWith(powerType) && (
                            conn1.IsOutput != conn2.IsOutput ||
                            conn1.Name == powerType ||
                            conn2.Name == powerType ||
                            conn1.Item.HasTag(powerType + "jb") ||
                            conn2.Item.HasTag(powerType + "jb")
                        );
                    }
                }

                // let the original function handle the rest
                return null;
            }, ILuaCsHook.HookMethodType.Before);

            // Change the item connection loading to allow for steam and kinetic networks
            // After the constructor correctly set the isPower property, for the steam and kinetic networks
            LuaCsSetup.Instance.Hook.HookMethod("Barotrauma.Items.Components.Connection",
            typeof(Barotrauma.Items.Components.Connection).GetConstructor(new[] { typeof(ContentXElement), typeof(ConnectionPanel), typeof(IdRemap) }),
            (object self, Dictionary<string, object> args) => {

                // Check if its an extra power type connection, if so, set the isPower property to true
                foreach (string powerType in ExtraPowerTypes)
                {
                    if (((Connection)self).Name == powerType || ((Connection)self).Name.StartsWith(powerType + "_in") || ((Connection)self).Name.StartsWith(powerType + "_out"))
                    {
                        ((Connection)self).IsPower = true;
                    }
                }

                return args;
            }, ILuaCsHook.HookMethodType.After);

            // Correctly assign the powerIn and powerOut for the steam and kinetic networks
            LuaCsSetup.Instance.Hook.HookMethod("Barotrauma.Items.Components.Powered",
            typeof(Barotrauma.Items.Components.Powered).GetMethod("OnItemLoaded", BindingFlags.Instance | BindingFlags.Public),
            (object self, Dictionary<string, object> args) => {
                Powered myself = (Powered)self;
                Item item = myself.Item;

                if (item.Connections == null) { return args; }

                if (item.HasTag("mtpriority"))
                {
                    LuaCsSetup.Instance.Game.AddPriorityItem(item);
                }

                // Get the highest priority device for this item
                PowerPriority priority = PowerPriority.Default; ;
                foreach (var dev in item.GetComponents<Powered>())
                {
                    PowerPriority currPrior = PowerPriority.Default;
                    if (dev is RelayComponent)
                    {
                        currPrior = PowerPriority.Relay;
                    }
                    else if (dev is PowerContainer)
                    {
                        currPrior = PowerPriority.Battery;
                    }
                    else if (dev is Reactor)
                    {
                        currPrior = PowerPriority.Reactor;
                    }
                    else if (dev.Item.HasTag("powerabsorber"))
                    {
                        currPrior = (PowerPriority)10;
                    }

                    if (currPrior > priority)
                    {
                        priority = currPrior;
                    }
                }

                // Find the powerIn and powerOut connections and assign them
                foreach (Connection c in item.Connections)
                {
                    if (!c.IsPower) { continue; }

                    c.Priority = priority;

                    foreach (string powerType in ExtraPowerTypes)
                    {
                        if (c.Name.StartsWith(powerType))
                        {
                            if (c.IsOutput || c.Name.StartsWith(powerType + "_out"))
                            {
                                if (myself.powerOuts.Count > 0)
                                {
                                    myself.powerOuts[0] = c;
                                }
                                else
                                {
                                    myself.powerOuts.Add(c);
                                }
                            }
                            else
                            {
                                myself.powerIn = c;
                            }
                        }
                    }
                }

                return args;
            }, ILuaCsHook.HookMethodType.After);

            // Remove the power_in pin from the relay check as it causes an uncessary warning that doesn't affect it's functionality
            RelayComponent.connectionPairs.Remove("power_in");
        }


    }
}
