using ModdingToolkit;

using System;
using Barotrauma;
using Barotrauma.Networking;
using System.Reflection;
using System.Collections.Generic;
using Microsoft.Xna.Framework;
using Barotrauma.Items.Components;
using System.Linq;
using System.Xml;
using Microsoft.VisualBasic;

namespace Mechtrauma
{
    public partial class Thermal : ItemComponent
    {
        public Thermal(Item item, ContentXElement element) : base(item, element)
        {

        }

        // Current Temperature
        public float Temperature = 150.0f; // 60 is default temperature 

        // Operating Temperatures

        [Editable, Serialize(0.0f, IsPropertySaveable.Yes, description: "Maximum Operating Temperature.", alwaysUseInstanceValues: true)]
        public float MaxOpTemp
        {
            get => maxOpTemp;
            set => maxOpTemp = value;
        }
        private float maxOpTemp = 0;

        [Editable, Serialize(0.0f, IsPropertySaveable.Yes, description: "Target Operating Temperature.", alwaysUseInstanceValues: true)]
        public float TargetOpTemp

        {
            get => targetOpTemp;
            set => targetOpTemp = value;
        }
        private float targetOpTemp;

        [Editable, Serialize(0.0f, IsPropertySaveable.Yes, description: "Minimum Operating Temperature.", alwaysUseInstanceValues: true)]
        public float MinOpTemp
        {
            get => minOpTemp;
            set => minOpTemp = value;
        }
        private float minOpTemp;

        [Editable, Serialize(0.0f, IsPropertySaveable.Yes, description: "Failure Temperature.", alwaysUseInstanceValues: true)]
        public float FailTemp
        {
            get => failTemp;
            set => failTemp = value;
        }
        private float failTemp;

        public float CumulativeStress;
        public float ExpansionStress;
        public float ContractionStress;

        // Temperature Tracking


        public List<float> TemperatureHistory = new List<float>();

        // update temperature and keep history of last 10 updates
        public void UpdateTemperature(float newTemperature)
        {
            Temperature = newTemperature;
            TemperatureHistory.Add(newTemperature);

            // only keep temp history for 10 updates
            if (TemperatureHistory.Count > 10)
            {                
                TemperatureHistory.RemoveAt(0);
            }
        }

        public float GetContractionStress()
        {
            if (TemperatureHistory.Count == 0 || maxOpTemp < 1.0f)
            {
                // Return a default value or handle the case when the history is empty
                return 0.0f; // You can replace this with a suitable default value
            }

            // Filter temperatures that are greater than or equal to the threshold
            var filteredTemps = TemperatureHistory.Where(temp => temp > MaxOpTemp);

            // Check if the filtered sequence is not empty
            if (filteredTemps.Any())
            {
                // Find the highest temperature in the filtered history
                float highTemp = filteredTemps.Max();

                // Find the index of the highest temperature
                int highTempIndex = TemperatureHistory.IndexOf(highTemp);

                // Filter temperatures starting from the index of the highest temperature
                var tempsAfterHigh = TemperatureHistory.Skip(highTempIndex);

                // Take the specified number of records and find the minimum
                float lowTempAfterHigh = tempsAfterHigh.DefaultIfEmpty().Min();

                // Return the difference if a valid temperature is found after the highest                
                float result = lowTempAfterHigh != 0.0f ? highTemp - lowTempAfterHigh : 0.0f;

                return result;
            }

            // Return a default value if the filtered sequence is empty
            return 0.0f; // You can replace this with a suitable default value
        }

        public float GetExpansionStress()
        {
            if (Temperature > maxOpTemp)
            {
                float result = Temperature - maxOpTemp;
                return result;

            }
            else
            { 
                return 0.0f;        
            }
        }
        public void CalcThermalStress()
        {
            float contractionStress = GetContractionStress();
            float expansionStress = GetExpansionStress();

            CumulativeStress += expansionStress;
            CumulativeStress += contractionStress;

            ContractionStress = contractionStress;
            ExpansionStress = expansionStress;
        }
    }
}
