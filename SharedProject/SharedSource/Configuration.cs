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
using ModdingToolkit;
using ModdingToolkit.Config;
using ModdingToolkit.Networking;
// ReSharper disable CommentTypo

namespace Mechtrauma;

public sealed class Configuration
{
    #region PUBLIC_API
#pragma warning disable CA1822
    private static Configuration? _instance = null;
    public static Configuration Instance
    {
        get
        {
            if (_instance is null)
                _instance = new();
            return _instance;
        }
    }
    
    // ---- PUBLIC READONLY CONFIG ---- //
    public bool DisableElectrocution => !_experimental.Setting_EnableElectrocution.Value;
    public float BearingDPS => GetDPS(_general.Setting_ThrustbearingServiceLife.Value); 
    public float BearingServiceLife => _general.Setting_ThrustbearingServiceLife.Value;
    public float CirculatorDPS => GetDPS(_general.Setting_CirculatorServiceLife.Value);
    public float CirculatorServiceLife => _general.Setting_CirculatorServiceLife.Value;
    public float DieselDrainRate => 1f;

    //Deteriorate the electric motor. NOTE: Reduced condtion from -0.5 to -0.1 on 9-24-22 and from: 0.1 to 0.25 on 9/25/22
    public float ElectricMotorDegradeRate => 0.25f;
    public float DieselGeneratorEfficiency => _advanced.Setting_DieselGeneratorEfficiency.Value;
    public float DieselHorsePowerRatioCL => _advanced.Setting_ConversionRatioHPtoDiesel.Value * 100f;
    public float DieselHorsePowerRatioDL => _advanced.Setting_ConversionRatioHPtoDiesel.Value * 10f;
    public float DieselHorsePowerRatioL => _advanced.Setting_ConversionRatioHPtoDiesel.Value;
    public float DieselOxygenRatioDL => _advanced.Setting_ConversionRatioOxygenToDiesel.Value * 0.1f;
    public float DieselOxygenRatioCL => _advanced.Setting_ConversionRatioOxygenToDiesel.Value * 0.01f;
    public float DieselOxygenRatioL => _advanced.Setting_ConversionRatioOxygenToDiesel.Value;
    public float DivingSuitEPP => _general.Setting_DivingSuitExtPressProtection.Value;
    public int DivingSuitServiceLife => _general.Setting_DivingSuitServiceLife.Value;
    public float FrictionBaseDPS => 1f;
    public float FuseboxDeterioration => _advanced.Setting_FuseboxDeteriorationRate.Value;
    public float FuseboxOvervoltDamage => _advanced.Setting_FuseboxOvervoltDamage.Value;
    public float OilBaseDPS => _test.Setting_OilBaseDPS.Value;
    public float OilFilterDPS => GetDPS(_general.Setting_OilFilterServiceLife.Value);
    public float OilFilterServiceLife => _general.Setting_OilFilterServiceLife.Value;
    public float OilFiltrationEP => _general.Setting_OilFiltrationEfficiencyRating.Value;
    public float OilFiltrationM => _general.Setting_OilFiltrationEfficiencyRating.Value / 100f;
    public float PumpGateDeteriorationRate => _experimental.Setting_PumpGateDeteriorationRate.Value;
    public float VentSpawnRate => _biotrauma.Setting_FungusSpawnRate.Value;

#pragma warning restore CA1822
    #endregion
    
    #region TYPEDEF


    public Configuration()
    { 
        _general = new(this);
        _advanced = new(this);
        _experimental = new(this);
        _biotrauma = new(this);
        _test = new(this);
    }

    public sealed class Settings_General
    {
        public readonly IConfigRangeFloat
            Setting_CirculatorServiceLife,            
            Setting_DivingSuitExtPressProtection,
            Setting_OilFilterServiceLife,
            Setting_OilFiltrationEfficiencyRating,
            Setting_ThrustbearingServiceLife;

        public readonly IConfigRangeInt
            Setting_DivingSuitServiceLife;

        public Settings_General(Configuration instance)
        {
            Setting_CirculatorServiceLife = ConfigManager.AddConfigRangeFloat(
                "CirculatorServiceLife", ModName,
                13f, 0.5f, 60f, GetStepCount(0.5f, 60f, 0.5f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Standard Circulator Service Life (min)",
                    DisplayCategory: "General"
                    ));
            
            Setting_DivingSuitServiceLife = ConfigManager.AddConfigRangeInt(
                "DivingSuitServiceLife", ModName,
                60, 0, 120, GetStepCount(0, 120, 10),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Diving Suit Service Life (min)",
                    DisplayCategory: "General"
                    ));
            Setting_DivingSuitExtPressProtection = ConfigManager.AddConfigRangeFloat(
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
                    ));
            Setting_OilFilterServiceLife = ConfigManager.AddConfigRangeFloat(
                "OilFilterServiceLife", ModName,
                6.5f, 0.5f, 60f, GetStepCount(0.5f, 60f, 0.5f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Standard Oil Filter Service Life (min)",
                    DisplayCategory: "General"
                    ));
            Setting_OilFiltrationEfficiencyRating = ConfigManager.AddConfigRangeFloat(
                "OilFilterEfficiencyRating", ModName,
                25f, 1f, 100f, GetStepCount(1f, 100f, 1f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Standard Oil Filter Efficiency Rating (%)",
                    DisplayCategory: "General"
                    ));
            Setting_ThrustbearingServiceLife = ConfigManager.AddConfigRangeFloat(
                "ThrustBearingServiceLife", ModName,
                13f, 0.5f, 60f, GetStepCount(0.5f, 60f, 0.5f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Standard Thrust Bearing Service Life (min)",
                    DisplayCategory: "General"
                    ));
        }
    }

    public sealed class Settings_Advanced
    {
        public readonly IConfigRangeFloat
            Setting_DieselGeneratorEfficiency,
            Setting_ConversionRatioHPtoDiesel,
            Setting_ConversionRatioOxygenToDiesel,
            Setting_FuseboxDeteriorationRate,
            Setting_FuseboxOvervoltDamage;

        public Settings_Advanced(Configuration instance)
        {
            Setting_DieselGeneratorEfficiency = ConfigManager.AddConfigRangeFloat(
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
                ));
            Setting_ConversionRatioHPtoDiesel = ConfigManager.AddConfigRangeFloat(
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
                ));
            Setting_ConversionRatioOxygenToDiesel = ConfigManager.AddConfigRangeFloat(
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
                ));
            Setting_FuseboxDeteriorationRate = ConfigManager.AddConfigRangeFloat(
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
                ));
            Setting_FuseboxOvervoltDamage = ConfigManager.AddConfigRangeFloat(
                "FuseOvervoltDamage", ModName,
                5f, 0f, 10f, GetStepCount(0f, 10f, 1f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Fusebox Overvolt Damage",
                    DisplayCategory: "Advanced"
                )); 
        }
    }

    public sealed class Settings_Experimental
    {
        public readonly IConfigEntry<bool> Setting_EnableElectrocution;
        public readonly IConfigRangeFloat Setting_PumpGateDeteriorationRate;

        public Settings_Experimental(Configuration instance)
        {
            Setting_EnableElectrocution = ConfigManager.AddConfigEntry(
                "EnableElectrocutionMechanic", ModName,
                false, networkSync: NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Enable Electrocution Mechanic",
                    DisplayCategory: "Experimental"
                ));
            Setting_PumpGateDeteriorationRate = ConfigManager.AddConfigRangeFloat(
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
                ));
        }
    }

    public sealed class Settings_Biotrauma
    {
        public readonly IConfigRangeFloat Setting_FungusSpawnRate;
        public Settings_Biotrauma(Configuration instance)
        {
            Setting_FungusSpawnRate = ConfigManager.AddConfigRangeFloat(
                "FungusSpawnRate", ModName,
                0f, 0f, 10f, GetStepCount(0f, 10f, 0.1f),
                NetworkSync.ServerAuthority, 
                displayData: new DisplayData(
                    DisplayName: "Fungus Spawn Rate",
                    DisplayCategory: "Biotrauma"
                ));
        }
    }

    public sealed class Settings_Test
    {
        public readonly IConfigRangeFloat Setting_OilBaseDPS;

        public Settings_Test(Configuration instance)
        {
            Setting_OilBaseDPS = ConfigManager.AddConfigRangeFloat(
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
                ));
        }
    }
    

    #endregion
    
    #region INTERNAL_OPS
    
    private static string ModName = "Mechtrauma";
    private static float GetPercentPerTick(float v) => v / 60f * 100;
    private static float GetDPS(float ssl) => 100f / ssl / 60f;
    private static int GetStepCount(float min, float max, float step) => (int)((max - min) / step + 1);

    // Settings Containers //
    private readonly Settings_General _general;
    private readonly Settings_Advanced _advanced;
    private readonly Settings_Experimental _experimental;
    private readonly Settings_Biotrauma _biotrauma;
    private readonly Settings_Test _test;

    #endregion
}