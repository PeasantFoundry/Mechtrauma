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
    public float FuseboxDeterioration => _deterioration.Setting_FuseboxDeteriorationRate.Value;
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
            Setting_FuseboxDeteriorationRate,
            Setting_ThrustbearingServiceLife,
            Setting_EngineBlockServiceLife,
            Setting_ExhaustManifoldGasketServiceLife;
        
        public readonly ISettingRangeBase<int>
           Setting_ExhaustManifoldServiceLife,
           Setting_DivingSuitServiceLife;


        //public readonly IConfigRangeInt;

        public Settings_Deterioration(IConfigService instance, ContentPackage selfPackage)
        { 
            instance.TryGetConfig(selfPackage, "FuelPumpServiceLife", out Setting_FuelPumpServiceLife);
            instance.TryGetConfig(selfPackage, "CirculatorServiceLife", out Setting_CirculatorServiceLife);
            instance.TryGetConfig(selfPackage, "DivingSuitServiceLife", out Setting_DivingSuitServiceLife);
            instance.TryGetConfig(selfPackage, "OilFilterServiceLife", out Setting_OilFilterServiceLife);
            instance.TryGetConfig(selfPackage, "OilFiltrationEfficiencyRating", out Setting_OilFiltrationEfficiencyRating);
            instance.TryGetConfig(selfPackage, "FuelFilterServiceLife", out Setting_FuelFilterServiceLife);
            instance.TryGetConfig(selfPackage, "FuseboxDeteriorationRate", out Setting_FuseboxDeteriorationRate);
            instance.TryGetConfig(selfPackage, "ThrustbearingServiceLife", out Setting_ThrustbearingServiceLife);
            instance.TryGetConfig(selfPackage, "EngineBlockServiceLife", out Setting_EngineBlockServiceLife);
            instance.TryGetConfig(selfPackage, "ExhaustManifoldServiceLife", out Setting_ExhaustManifoldServiceLife);
            instance.TryGetConfig(selfPackage, "ExhaustManifoldGasketServiceLife", out Setting_ExhaustManifoldGasketServiceLife);
        }
    }

    public sealed class Settings_General
    {
        public readonly ISettingRangeBase<float>
            Setting_DivingSuitExtPressProtection;

        public Settings_General(IConfigService instance, ContentPackage selfPackage)
        { 
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
            Setting_FuseboxOvervoltDamage,
            Setting_LuaUpdateInterval,
            Setting_PriorityUpdateInterval;
            

        public Settings_Advanced(IConfigService instance, ContentPackage selfPackage)
        {
            instance.TryGetConfig(selfPackage, "PartFaultRangeModifier", out Setting_PartFaultRangeModifier);
            instance.TryGetConfig(selfPackage, "DieselGeneratorEfficiency", out Setting_DieselGeneratorEfficiency);
            instance.TryGetConfig(selfPackage, "ConversionRatioHPtoDiesel", out Setting_ConversionRatioHPtoDiesel);
            instance.TryGetConfig(selfPackage, "ConversionRatioOxygenToDiesel", out Setting_ConversionRatioOxygenToDiesel);
            instance.TryGetConfig(selfPackage, "FuseboxOvervoltDamage", out Setting_FuseboxOvervoltDamage);
            instance.TryGetConfig(selfPackage, "LuaUpdateInterval", out Setting_LuaUpdateInterval);
            instance.TryGetConfig(selfPackage, "PriorityUpdateInterval", out Setting_PriorityUpdateInterval);
        }
    }

    public sealed class Settings_Experimental
    {
        public readonly ISettingBase<bool> Setting_EnableElectrocution;
        public readonly ISettingRangeBase<float> Setting_PumpGateDeteriorationRate;

        public Settings_Experimental(IConfigService instance, ContentPackage selfPackage)
        {
            instance.TryGetConfig(selfPackage, "EnableElectrocution", out Setting_EnableElectrocution);
            instance.TryGetConfig(selfPackage, "PumpGateDeteriorationRate", out Setting_PumpGateDeteriorationRate);
        }
    }

    public sealed class Settings_Biotrauma
    {
        public readonly ISettingRangeBase<float> Setting_FungusSpawnRate;
        public Settings_Biotrauma(IConfigService instance, ContentPackage selfPackage)
        {
            instance.TryGetConfig(selfPackage, "FungusSpawnRate", out Setting_FungusSpawnRate);
        }
        
        
    }

    public sealed class Settings_Test
    {
        public readonly ISettingRangeBase<float> Setting_OilBaseDPS;

        public Settings_Test(IConfigService instance, ContentPackage selfPackage)
        {
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