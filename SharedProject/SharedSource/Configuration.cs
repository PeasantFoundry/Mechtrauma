using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Collections.Immutable;
using System.Reflection;
using System.Reflection.Emit;
using System.Runtime.CompilerServices;
using System.Linq;
using Microsoft.Xna.Framework;

using Barotrauma;
using Barotrauma.Extensions;
using Barotrauma.LuaCs;
using Barotrauma.LuaCs.Data;

// ReSharper disable CommentTypo

namespace Mechtrauma;

public sealed class Configuration
{
    #region PUBLIC_API
#pragma warning disable CA1822
    
    // ---- PUBLIC READONLY CONFIG ---- //
    public bool DisableElectrocution => !_experimental.Setting_EnableElectrocution.Value;
    public float BearingDPS => GetDPS(_deterioration.Setting_ThrustbearingServiceLife.Value); 
    public float BearingServiceLife => _deterioration.Setting_ThrustbearingServiceLife.Value;
    public float CirculatorDPS => GetDPS(_deterioration.Setting_CirculatorServiceLife.Value);
    public float CirculatorServiceLife => _deterioration.Setting_CirculatorServiceLife.Value;
    public float DieselDrainRate => 1f;

    //Deteriorate the electric motor. NOTE: Reduced condition from -0.5 to -0.1 on 9-24-22 and from: 0.1 to 0.25 on 9/25/22
    public float ElectricMotorDegradeRate => 0.25f;
    public float PartFaultRangeModifier => _advanced.Setting_PartFaultRangeModifier.Value;
    public float DieselGeneratorEfficiency => _advanced.Setting_DieselGeneratorEfficiency.Value;
    public float DieselHorsePowerRatioCL => _advanced.Setting_ConversionRatioHPtoDiesel.Value * 100f;
    public float DieselHorsePowerRatioDL => _advanced.Setting_ConversionRatioHPtoDiesel.Value * 10f;
    public float DieselHorsePowerRatioL => _advanced.Setting_ConversionRatioHPtoDiesel.Value;
    public float DieselOxygenRatioDL => _advanced.Setting_ConversionRatioOxygenToDiesel.Value * 0.1f;
    public float DieselOxygenRatioCL => _advanced.Setting_ConversionRatioOxygenToDiesel.Value * 0.01f;
    public float DieselOxygenRatioL => _advanced.Setting_ConversionRatioOxygenToDiesel.Value;
    public float DivingSuitEPP => _general.Setting_DivingSuitExtPressProtection.Value;
    public int DivingSuitServiceLife => _deterioration.Setting_DivingSuitServiceLife.Value;
    public float FrictionBaseDPS => 1f;
    public float FuseboxDeterioration => _advanced.Setting_FuseboxDeteriorationRate.Value;
    public float FuseboxOvervoltDamage => _advanced.Setting_FuseboxOvervoltDamage.Value;
    public float OilBaseDPS => _test.Setting_OilBaseDPS.Value;
    public float OilFilterDPS => GetDPS(_deterioration.Setting_OilFilterServiceLife.Value);
    public float OilFilterServiceLife => _deterioration.Setting_OilFilterServiceLife.Value;
    public float FuelFilterSLD => GetSLD(_deterioration.Setting_FuelFilterServiceLife.Value);
    public float FuelFilterDPS => GetDPS(_deterioration.Setting_FuelFilterServiceLife.Value);
    public float FuelFilterServiceLife => _deterioration.Setting_FuelFilterServiceLife.Value;
    public float FuelPumpSLD => GetSLD(_deterioration.Setting_FuelPumpServiceLife.Value);
    public float FuelPumpDPS => GetDPS(_deterioration.Setting_FuelPumpServiceLife.Value);
    public float FuelPumpServiceLife => _deterioration.Setting_FuelPumpServiceLife.Value;
    public float OilFiltrationEP => _deterioration.Setting_OilFiltrationEfficiencyRating.Value;
    public float OilFiltrationM => _deterioration.Setting_OilFiltrationEfficiencyRating.Value / 100f;
    public float EngineBlockDPS => GetDPS(_deterioration.Setting_EngineBlockServiceLife.Value);
    public float EngineBlockServiceLife => _deterioration.Setting_EngineBlockServiceLife.Value;
    public float ExhaustManifoldDPS => GetDPS(_deterioration.Setting_ExhaustManifoldServiceLife.Value);
    public int ExhaustManifoldServiceLife => _deterioration.Setting_ExhaustManifoldServiceLife.Value;
    public float ExhaustManifoldGasketDPS => GetDPS(_deterioration.Setting_ExhaustManifoldGasketServiceLife.Value);
    public float ExhaustManifoldGasketServiceLife => _deterioration.Setting_ExhaustManifoldGasketServiceLife.Value;

    public float PumpGateDeteriorationRate => _experimental.Setting_PumpGateDeteriorationRate.Value;
    public float VentSpawnRate => _biotrauma.Setting_FungusSpawnRate.Value;

    public float DeltaTime => _advanced.Setting_LuaUpdateInterval.Value;
    public float PriorityDeltaTime => _advanced.Setting_PriorityUpdateInterval.Value;

#pragma warning restore CA1822
    #endregion
    
    #region TYPEDEF


    private readonly ContentPackage _selfPackage;
    private readonly IConfigService _configService;
    
    public Configuration(IConfigService configService, ContentPackage selfPackage)
    {
        _configService = configService;
        _selfPackage = selfPackage;
        _general = new(configService, selfPackage);
        _deterioration = new(configService, selfPackage);
        _advanced = new(configService, selfPackage);
        _experimental = new(configService, selfPackage);
        _biotrauma = new(configService, selfPackage);
        _test = new(configService, selfPackage);
    }

    //DETERIORATION SECTION: 
    public sealed class Settings_Deterioration
    {
        public readonly ISettingRangeBase<float>
            Setting_CirculatorServiceLife,
            Setting_OilFilterServiceLife,
            Setting_OilFiltrationEfficiencyRating,
            Setting_FuelFilterServiceLife,
            Setting_FuelPumpServiceLife,
            Setting_ThrustbearingServiceLife,
            Setting_EngineBlockServiceLife,
            Setting_ExhaustManifoldGasketServiceLife;
        
        public readonly ISettingRangeBase<int>
           Setting_ExhaustManifoldServiceLife,
           Setting_DivingSuitServiceLife;


        //public readonly IConfigRangeInt;

        public Settings_Deterioration(IConfigService instance, ContentPackage selfPackage)
        {
            /*Setting_FuelPumpServiceLife = ConfigManager.AddConfigRangeFloat(
            "FuelPumpServiceLife", ModName,
            30f, 1f, 120f, GetStepCount(1f, 120f, 1f),
            NetworkSync.ServerAuthority,
            displayData: new DisplayData(
                DisplayName: "Standard Fuel Pump Service Life (min)",
                DisplayCategory: "Deterioration"
                ));*/
           instance.TryGetConfig(selfPackage, "FuelPumpServiceLife", out Setting_FuelPumpServiceLife);
            
            /*Setting_CirculatorServiceLife = ConfigManager.AddConfigRangeFloat(
            "CirculatorServiceLife", ModName,
            13f, 0.5f, 60f, GetStepCount(0.5f, 60f, 0.5f),
            NetworkSync.ServerAuthority,
            displayData: new DisplayData(
                DisplayName: "Standard Circulator Service Life (min)",
                DisplayCategory: "Deterioration"
            ));*/
            instance.TryGetConfig(selfPackage, "CirculatorServiceLife", out Setting_CirculatorServiceLife);
            
            /*Setting_DivingSuitServiceLife = ConfigManager.AddConfigRangeInt(
            "DivingSuitServiceLife", ModName,
            60, 0, 120, GetStepCount(0, 120, 10),
            NetworkSync.ServerAuthority,
            displayData: new DisplayData(
                DisplayName: "Diving Suit Service Life (min)",
                DisplayCategory: "Deterioration"
                ));*/
            
            instance.TryGetConfig(selfPackage, "DivingSuitServiceLife", out Setting_DivingSuitServiceLife);
            
            /*Setting_OilFilterServiceLife = ConfigManager.AddConfigRangeFloat(
               "OilFilterServiceLife", ModName,
               6.5f, 0.5f, 60f, GetStepCount(0.5f, 60f, 0.5f),
               NetworkSync.ServerAuthority,
               displayData: new DisplayData(
                   DisplayName: "Standard Oil Filter Service Life (min)",
                   DisplayCategory: "Deterioration"
                   ));*/
            
            instance.TryGetConfig(selfPackage, "OilFilterServiceLife", out Setting_OilFilterServiceLife);
            
            /*Setting_OilFiltrationEfficiencyRating = ConfigManager.AddConfigRangeFloat(
                "OilFilterEfficiencyRating", ModName,
                25f, 1f, 100f, GetStepCount(1f, 100f, 1f),
                NetworkSync.ServerAuthority,
                displayData: new DisplayData(
                    DisplayName: "Standard Oil Filter Efficiency Rating (%)",
                    DisplayCategory: "Deterioration"
                    ));*/
            
            instance.TryGetConfig(selfPackage, "OilFiltrationEfficiencyRating", out Setting_OilFiltrationEfficiencyRating);
            
            /*Setting_FuelFilterServiceLife = ConfigManager.AddConfigRangeFloat(
                "FuelFilterServiceLife", ModName,
                6.5f, 0.5f, 60f, GetStepCount(0.5f, 60f, 0.5f),
                NetworkSync.ServerAuthority,
                displayData: new DisplayData(
                    DisplayName: "Standard Fuel Filter Service Life (min)",
                    DisplayCategory: "Deterioration"
                    ));*/
            
            instance.TryGetConfig(selfPackage, "FuelFilterServiceLife", out Setting_FuelFilterServiceLife);
            
            /*Setting_ThrustbearingServiceLife = ConfigManager.AddConfigRangeFloat(
                "ThrustBearingServiceLife", ModName,
                13f, 0.5f, 60f, GetStepCount(0.5f, 60f, 0.5f),
                NetworkSync.ServerAuthority,
                displayData: new DisplayData(
                    DisplayName: "Standard Thrust Bearing Service Life (min)",
                    DisplayCategory: "Deterioration"
                    ));*/
            
            instance.TryGetConfig(selfPackage, "ThrustbearingServiceLife", out Setting_ThrustbearingServiceLife);
            
            /*Setting_EngineBlockServiceLife = ConfigManager.AddConfigRangeFloat(
                "EngineBlockServiceLife", ModName,
                300f, 5f, 500f, GetStepCount(100f, 100f, 4.0f),
                NetworkSync.ServerAuthority,
                displayData: new DisplayData(
                    DisplayName: "Standard Engine Block Service Life (min)",
                    DisplayCategory: "Deterioration"
                    ));*/
            
            instance.TryGetConfig(selfPackage, "EngineBlockServiceLife", out Setting_EngineBlockServiceLife);
            
            /*Setting_ExhaustManifoldServiceLife = ConfigManager.AddConfigRangeInt(
                "ExhaustManifoldServiceLife", ModName,
                 60, 0, 120, GetStepCount(0, 120, 10),
                NetworkSync.ServerAuthority,
                displayData: new DisplayData(
                    DisplayName: "Standard Exhaust Manifold Service Life (min)",
                    DisplayCategory: "Deterioration"
                    ));*/

            instance.TryGetConfig(selfPackage, "ExhaustManifoldServiceLife", out Setting_ExhaustManifoldServiceLife);
            
            /*Setting_ExhaustManifoldGasketServiceLife = ConfigManager.AddConfigRangeFloat(
                "ExhaustManifoldGasketServiceLife", ModName,
                30f, 1.0f, 150f, GetStepCount(15f, 150f, 1.0f),
                NetworkSync.ServerAuthority,
                displayData: new DisplayData(
                    DisplayName: "Standard Exhaust Manifold Service Life (min)",
                    DisplayCategory: "Deterioration"
                    ));*/
            
            instance.TryGetConfig(selfPackage, "ExhaustManifoldGasketServiceLife", out Setting_ExhaustManifoldGasketServiceLife);

        }
    }

    public sealed class Settings_General
    {
        public readonly ISettingRangeBase<float>

            Setting_DivingSuitExtPressProtection;

        //public readonly IConfigRangeInt;
         


        public Settings_General(IConfigService instance, ContentPackage selfPackage)
        {       

            /*Setting_DivingSuitExtPressProtection = ConfigManager.AddConfigRangeFloat(
                "DivingSuitExtendedPressureProtection", ModName,
                2f, 1f, 2.5f, GetStepCount(1f, 2.5f, 0.1f),
                NetworkSync.ServerAuthority, displayData: new DisplayData(
                    DisplayName: "Diving Suit Extended Pressure Protection (multiplier)",
                    DisplayCategory: "General",
#if DEBUG
                    MenuCategory: Category.Gameplay
#else
                    MenuCategory: Category.Ignore
#endif
                    )); */
            
            instance.TryGetConfig(selfPackage, "DivingSuitExtPressProtection", out Setting_DivingSuitExtPressProtection);

        }
    }


    public sealed class Settings_Advanced
    {
        public readonly ISettingRangeBase<float>
            Setting_PartFaultRangeModifier,
            Setting_DieselGeneratorEfficiency,
            Setting_ConversionRatioHPtoDiesel,
            Setting_ConversionRatioOxygenToDiesel,
            Setting_FuseboxDeteriorationRate,
            Setting_FuseboxOvervoltDamage,
            Setting_LuaUpdateInterval,
            Setting_PriorityUpdateInterval;
            

        public Settings_Advanced(IConfigService instance, ContentPackage selfPackage)
        {
            /*Setting_PartFaultRangeModifier = ConfigManager.AddConfigRangeFloat(
                "PartFaultRangeModifier", ModName,
                1f, 1f, 10f, GetStepCount(1f, 10f, 0.5f),
                NetworkSync.ServerAuthority,
                displayData: new DisplayData(
                    DisplayName: "Part Fault Range Modifier",
                    DisplayCategory: "Advanced",
                    #if DEBUG
                    MenuCategory: Category.Gameplay
                    #else
                    MenuCategory: Category.Ignore
                    #endif
                ));*/
            
            instance.TryGetConfig(selfPackage, "PartFaultRangeModifier", out Setting_PartFaultRangeModifier);
            
            /*Setting_DieselGeneratorEfficiency = ConfigManager.AddConfigRangeFloat(
                "DieselGeneratorEfficiency", ModName,
                0.3f, 1f, 20f, GetStepCount(1f, 20f, 1f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Diesel Generator Efficiency",
                    DisplayCategory: "Advanced",
                    #if DEBUG
                    MenuCategory: Category.Gameplay
                    #else
                    MenuCategory: Category.Ignore
                    #endif
                ));*/

            instance.TryGetConfig(selfPackage, "DieselGeneratorEfficiency", out Setting_DieselGeneratorEfficiency);
            
            
            /*Setting_ConversionRatioHPtoDiesel = ConfigManager.AddConfigRangeFloat(
                "ConversionRatioHPtoDieselFuel", ModName,
                0.25f, 0.2f, 1.0f, GetStepCount(0.2f, 1.0f, 0.05f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Conversion Ratio: kWh : Diesel (1L)",
                    DisplayCategory: "Advanced",
                    #if DEBUG
                    MenuCategory: Category.Gameplay
                    #else
                    MenuCategory: Category.Gameplay
                    //MenuCategory: Category.Ignore
                    #endif
                ));*/
            
            instance.TryGetConfig(selfPackage, "ConversionRatioHPtoDiesel", out Setting_ConversionRatioHPtoDiesel);
            
            
            /*Setting_ConversionRatioOxygenToDiesel = ConfigManager.AddConfigRangeFloat(
                "ConversionRatioOxygenToDieselFuel", ModName,
                7.0f, 1.0f, 14f, GetStepCount(1f, 14f, 1f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Conversion Ratio: Oxygen Unit : Diesel (1L)",
                    DisplayCategory: "Advanced",
                    #if DEBUG
                    MenuCategory: Category.Gameplay
                    #else
                    MenuCategory: Category.Ignore
                    #endif
                ));*/
            
            instance.TryGetConfig(selfPackage, "ConversionRatioOxygenToDiesel", out Setting_ConversionRatioOxygenToDiesel);
            
            /*Setting_FuseboxDeteriorationRate = ConfigManager.AddConfigRangeFloat(
                "FuseboxDeviceDeteriorationRate", ModName,
                0.12f, 0f, 1f, GetStepCount(0f, 1f, 0.05f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Fusebox Deterioration Rate",
                    DisplayCategory: "Advanced",
                    #if DEBUG
                    MenuCategory: Category.Gameplay
                    #else
                    MenuCategory: Category.Ignore
                    #endif
                ));*/
            
            instance.TryGetConfig(selfPackage, "FuseboxDeteriorationRate", out Setting_FuseboxDeteriorationRate);
            
            /*Setting_FuseboxOvervoltDamage = ConfigManager.AddConfigRangeFloat(
                "FuseOvervoltDamage", ModName,
                5f, 0f, 10f, GetStepCount(0f, 10f, 1f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Fusebox Overvolt Damage",
                    DisplayCategory: "Advanced"
                ));*/
            
            instance.TryGetConfig(selfPackage, "FuseboxOvervoltDamage", out Setting_FuseboxOvervoltDamage);
            

            /*Setting_LuaUpdateInterval = ConfigManager.AddConfigRangeFloat(
                "LuaUpdateInterval", ModName,
                2f, 0.25f, 4f, GetStepCount(0.25f, 4f, 11),
                NetworkSync.ServerAuthority,
                displayData: new DisplayData(
                    DisplayName: "Lua Update Interval",
                    DisplayCategory: "Advanced"
                    ));*/
            
            instance.TryGetConfig(selfPackage, "LuaUpdateInterval", out Setting_LuaUpdateInterval);
            
            
            /*Setting_PriorityUpdateInterval = ConfigManager.AddConfigRangeFloat(
                "PriorityUpdateInterval", ModName,
                0.25f, 0.01666666667f, 1f, GetStepCount(0.01666666667f, 1f, 61),
                NetworkSync.ServerAuthority,
                displayData: new DisplayData(
                    DisplayName: "Priority Lua Update Interval",
                    DisplayCategory: "Advanced"
                ));*/

            instance.TryGetConfig(selfPackage, "PriorityUpdateInterval", out Setting_PriorityUpdateInterval);
            
        }
    }

    public sealed class Settings_Experimental
    {
        public readonly ISettingBase<bool> Setting_EnableElectrocution;
        public readonly ISettingRangeBase<float> Setting_PumpGateDeteriorationRate;

        public Settings_Experimental(IConfigService instance, ContentPackage selfPackage)
        {
            /*Setting_EnableElectrocution = ConfigManager.AddConfigEntry(
                "EnableElectrocutionMechanic", ModName,
                false, networkSync: NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Enable Electrocution Mechanic",
                    DisplayCategory: "Experimental"
                ));*/
            
            instance.TryGetConfig(selfPackage, "EnableElectrocution", out Setting_EnableElectrocution);

            
            /*Setting_PumpGateDeteriorationRate = ConfigManager.AddConfigRangeFloat(
                "PumpGateDeteriorationRateMulti", ModName,
                1f, 0f, 100f, GetStepCount(0f, 100f, 0.1f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Pump Gate Deterioration Rate (Multi)",
                    DisplayCategory: "Experimental",
                    #if DEBUG
                    MenuCategory: Category.Gameplay
                    #else
                    MenuCategory: Category.Ignore
                    #endif
                ));*/
            
            instance.TryGetConfig(selfPackage, "PumpGateDeteriorationRate", out Setting_PumpGateDeteriorationRate);

        }
    }

    public sealed class Settings_Biotrauma
    {
        public readonly ISettingRangeBase<float> Setting_FungusSpawnRate;
        public Settings_Biotrauma(IConfigService instance, ContentPackage selfPackage)
        {
            /*Setting_FungusSpawnRate = ConfigManager.AddConfigRangeFloat(
                "FungusSpawnRate", ModName,
                0f, 0f, 10f, GetStepCount(0f, 10f, 0.1f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Fungus Spawn Rate",
                    DisplayCategory: "Biotrauma"
                ));*/
            
            instance.TryGetConfig(selfPackage, "FungusSpawnRate", out Setting_FungusSpawnRate);

        }
        
        
    }

    public sealed class Settings_Test
    {
        public readonly ISettingRangeBase<float> Setting_OilBaseDPS;

        public Settings_Test(IConfigService instance, ContentPackage selfPackage)
        {
            /*Setting_OilBaseDPS = ConfigManager.AddConfigRangeFloat(
                "OilBaseDPS", ModName,
                1f, 1f, 20f, GetStepCount(1f, 20f, 1f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Oil Base DPS",
                    DisplayCategory: "Test",
                    #if DEBUG
                    MenuCategory: Category.Gameplay
                    #else
                    MenuCategory: Category.Ignore
                    #endif
                ));*/
            
            instance.TryGetConfig(selfPackage, "OilBaseDPS", out Setting_OilBaseDPS);
            
        }
    }
    

    #endregion
    
    #region INTERNAL_OPS
    
    private static string ModName = "Mechtrauma";
    private static float GetPercentPerTick(float v) => v / 60f * 100;
    private static float GetDPS(float ssl) => 100f / ssl / 60f; // 100 condition_max / ssl / tickrate | ORG = (100f / value) / 60 
    private static float GetSLD(float ssl) => ssl * 60f / 2f; //SLD = ServiceLifeDelta - may need to move MT delta to here
    private static int GetStepCount(float min, float max, float step) => (int)((max - min) / step + 1);

    // Settings Containers //
    private readonly Settings_General _general;
    private readonly Settings_Deterioration _deterioration;
    private readonly Settings_Advanced _advanced;
    private readonly Settings_Experimental _experimental;
    private readonly Settings_Biotrauma _biotrauma;
    private readonly Settings_Test _test;

    #endregion
}