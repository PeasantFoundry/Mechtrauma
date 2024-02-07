using Barotrauma;
using Barotrauma.Items.Components;
using FarseerPhysics.Dynamics;

namespace Mechtrauma.TransferSystems;

public class FluidTransfer<T1,T2> : ItemComponent where T1 : class, IFluidContainer<T2>, new() where T2 : struct, IFluidData
{
    #region VARS

    [Editable, Serialize(true, IsPropertySaveable.Yes, "Are transfers enabled?")]
    public bool IsEnabled { get; set; }

    private float _maxFlowRate;
    [Editable, Serialize(float.MaxValue-1f, IsPropertySaveable.Yes, "Max flow rate (L).")]
    public float MaxFlowRate
    {
        get => _maxFlowRate;
        set => _maxFlowRate = Math.Max(0, value);
    }

    private float _deltaPressureRatio;

    [Editable(0.1f, 10f), Serialize(1f, IsPropertySaveable.Yes, "Exit/Outlet pressure adjustment multiplier.")]
    public float DeltaPressureRatio
    {
        get => _deltaPressureRatio;
        set => _deltaPressureRatio = Math.Clamp(value, 0.1f, 10f);
    }

    private float _velocityOutputRatio;

    [Editable(0.1f, 10f), Serialize(1f, IsPropertySaveable.Yes, "Exit/Outlet velocity adjustment multiplier.")]
    public float VelocityOutputRatio
    {
        get => _velocityOutputRatio;
        set => _velocityOutputRatio = Math.Clamp(value, 0.1f, 10f);
    }
    
    public static readonly string SIGNAL_VOLUMETRIC_RATE = "output_flow_rate";
    public static readonly string SIGNAL_PRESSURE = "output_pressure";
    public static readonly string SIGNAL_VELOCITY = "output_velocity";

    private int _ticksUntilUpdate = 0;

    #endregion
    
    public FluidTransfer(Item item, ContentXElement element) : base(item, element)
    {
        IsActive = true;
    }

    public override void OnItemLoaded()
    {
        base.OnItemLoaded();
        // randomize the initial count to stagger updates a bit and reduce lag spikes from network updates.
        _ticksUntilUpdate = Rand.Range(0, FluidSystemData.WaitTicksBetweenUpdates);    
    }

    public override void Update(float deltaTime, Camera cam)
    {
        base.Update(deltaTime, cam);
        if (IsEnabled)
        {
            _ticksUntilUpdate--;
            if (_ticksUntilUpdate < 1)
            {
                _ticksUntilUpdate = FluidSystemData.WaitTicksBetweenUpdates;
                UpdateLiquidTransfers();
            }
        }
    }

    /// <summary>
    /// The FluidTransfer system is stateless so producer and consumers must be built every update. This is because
    /// there isn't a graceful way to track changed/dirty item connections outside of internal vanilla code.
    /// </summary>
    private void UpdateLiquidTransfers()
    {
        IFluidDevice<T1, T2>? producer = null;
        List<IFluidDevice<T1, T2>> consumers = new();

        if (TryGetProducerAndConsumers())
        {
            // get liquid containers
            var producerTank = producer!.GetPrefContainerByGroup(T2.SymbolConnOutput);
            var consumerTanks = new List<T1>();

            // exit if no src
            if (producerTank is null)
                return;
            
            // exit if no vol
            if (producerTank.Volume < 0.001f)
                return;
            
            // get valid consumers
            var sampleLiquid = producerTank.GetFluidSample<List<T2>>();

            if (!sampleLiquid.Any())
                return;

            var sampleProperties = FluidDatabase.Instance.GetFluidProperties(sampleLiquid[0].Identifier,
                FluidProperties.PhaseType.Liquid);
            // for performance purposes, we take the acceleration ratio of the first fluid only. 
            // if needed, should be changed to take the acceleration from the highest volume fluid.
            // However, this requires withdrawing fluid pre-emptively.
            var sampleAccelRatio = sampleProperties?.AccelerationRatio ?? 0f;

            foreach (IFluidDevice<T1, T2> device in consumers)
            {
                foreach (var container in device.GetFluidContainersByGroup<List<T1>>(T2.SymbolConnInput))       
                {
                    if (container is null)
                        continue;
                    if (container.Pressure - producerTank.Pressure > float.Epsilon) // back pressure excess
                        continue;
                    if (container.GetApertureSizeForConnection(T2.SymbolConnInput) < float.Epsilon) // valve closed
                        continue;
                    if (!container.CanPutFluids(sampleLiquid))
                        continue;
                    consumerTanks.Add(container);
                }
            }
            
            // calculate fluid proportions per container.          
            float sumProportions = 0;
            int tankCount = consumerTanks.Count;
            // calculate proportions
            // stack overflow protection limit of 64 => ~1.2KB max stack mem
            
            // alloc memory
            Span<float> proportionsAbs = tankCount < 64 ? stackalloc float[tankCount] : new float[tankCount];
            Span<float> deltaPressures = tankCount < 64 ? stackalloc float[tankCount] : new float[tankCount];
            Span<float> apertures = tankCount < 64 ? stackalloc float[tankCount] : new float[tankCount];
            Span<float> velocities = tankCount < 64 ? stackalloc float[tankCount] : new float[tankCount];
            Span<float> toTransferVolume = tankCount < 64 ? stackalloc float[tankCount] : new float[tankCount];

            var consumerApertureSum = 0f;
            for (int i = 0; i < consumerTanks.Count; i++)
            {
                apertures[i] = consumerTanks[i].GetApertureSizeForConnection(T2.SymbolConnInput);
                consumerApertureSum += apertures[i];
            }
            
            var producerAperture = producerTank.GetApertureSizeForConnection(T2.SymbolConnOutput);
            var maxOutVolume = Math.Min(producerTank.Velocity * Math.Min(producerAperture, consumerApertureSum), MaxFlowRate * FluidSystemData.FixedDeltaTime);
            var proportionRel = 0f;
            
            // calculate stats
            for (int i = 0; i < consumerTanks.Count; i++)
            {
                var tank = consumerTanks[i];
                deltaPressures[i] = (producerTank.Pressure - tank.Pressure) * DeltaPressureRatio;
                proportionsAbs[i] = deltaPressures[i] * apertures[i];
                sumProportions += proportionsAbs[i]; 
                velocities[i] = (producerTank.Velocity + deltaPressures[i] * sampleAccelRatio) * VelocityOutputRatio;
            }

            for (int i = 0; i < consumerTanks.Count; i++)
            {
                proportionRel = proportionsAbs[i] / sumProportions; // get proportionate fluid transfer. range 0 > 1
                // lower of volume from producer and consumer tank limits
                toTransferVolume[i] = Math.Min(maxOutVolume * proportionRel,
                    consumerTanks[i].GetMaxFreeVolume(sampleLiquid));
            }
            
            // extract volume and send 
            var consumerApertureRatio = producerAperture / consumerApertureSum;
            for (int i = 0; i < consumerTanks.Count; i++)
            {
                if (consumerTanks[i].PutFluids(
                        producerTank.TakeFluidProportional<List<T2>>(toTransferVolume[i]), 
                        overrideChecks: true))  // we already ran checks earlier
                {
                    consumerTanks[i].UpdateForVelocity(velocities[i] * consumerApertureRatio); //velocity different form fluids
                    consumerTanks[i].UpdateForPressure(producerTank.Pressure + deltaPressures[i]);
                }
            }
        } 
    
        
        bool TryGetProducerAndConsumers()
        {
            bool success = false;
            try
            {
                bool foundInput = false;
                foreach (Connection connection in Item.Connections)
                {
                    if (connection.Name == T2.SymbolConnInput) // found input on self conn panel.
                    {
                        if (foundInput)
                            continue;
                        
                        foreach (Connection recipient in connection.Recipients)
                        {
                            if (foundInput)
                                break;
                            if (recipient.Name != T2.SymbolConnOutput) // we're skipping anything that isn't an liquid out connection.
                                continue;

                            foreach (ItemComponent component in recipient.Item.Components)  
                            {
                                // find the first compat IFluidDevice with an liquid out.
                                if (component is IFluidDevice<T1, T2> device)    //outputs liquid
                                {
                                    // we found our producer.
                                    producer = device;
                                    foundInput = true;
                                    break;
                                }
                            }
                        }
                    }
                    else if (connection.Name == T2.SymbolConnOutput) // found output on self conn panel.
                    {
                        foreach (Connection recipient in connection.Recipients)
                        {
                            if (recipient.Name != T2.SymbolConnInput) // we're skipping anything that's not an input.
                                continue;

                            foreach (ItemComponent component in recipient.Item.Components)
                            {
                                if (component is IFluidDevice<T1, T2> device)
                                {
                                    consumers.Add(device);
                                }
                            }
                        }
                    }
                }

                success = true;
            }
            catch
            {
                success = false;
            }

            return success && producer is {} && consumers.Any();
        }
    }
}