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
    private ConnectionPanel? _panel;

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
        _panel = Item.GetComponent<ConnectionPanel>() ?? null;
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
            var consumerTanks = new List<T1>(16);

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
            Span<float> apertures = tankCount < 64 ? stackalloc float[tankCount] : new float[tankCount];
            Span<float> velocities = tankCount < 64 ? stackalloc float[tankCount] : new float[tankCount];

            var consumerApertureSum = 0f;
            for (int i = 0; i < consumerTanks.Count; i++)
            {
                apertures[i] = consumerTanks[i].GetApertureSizeForConnection(T2.SymbolConnInput);
                consumerApertureSum += apertures[i];
            }
            
            var producerAperture = producerTank.GetApertureSizeForConnection(T2.SymbolConnOutput);
            var maxOutVolume = Math.Min(
                producerTank.Velocity * Math.Min(producerAperture, consumerApertureSum), 
                MaxFlowRate * FluidSystemData.FixedDeltaTime);
            var consumerApertureRatio = producerAperture / consumerApertureSum;
            
            // calculate stats
            for (int i = 0; i < consumerTanks.Count; i++)
            {
                var tank = consumerTanks[i];
                float deltaPressure = (producerTank.Pressure - tank.Pressure) * DeltaPressureRatio;
                proportionsAbs[i] = deltaPressure * apertures[i];
                sumProportions += proportionsAbs[i]; 
                velocities[i] = (producerTank.Velocity + deltaPressure * sampleAccelRatio) * VelocityOutputRatio * consumerApertureRatio;
            }

            // extract volume and send 
            for (int i = 0; i < consumerTanks.Count; i++)
            {
                float toTransferVolume = Math.Min(maxOutVolume * proportionsAbs[i] / sumProportions,
                    consumerTanks[i].GetMaxFreeVolume(sampleLiquid));
                
                if (toTransferVolume < 0.01f)
                    continue;
                
                if (consumerTanks[i].PutFluids(
                        producerTank.TakeFluidProportional<List<T2>>(toTransferVolume), 
                        overrideChecks: true))  // we already ran checks earlier
                {
                    consumerTanks[i].UpdateForVelocity(velocities[i]); 
                    consumerTanks[i].UpdateForPressure(producerTank.Pressure * DeltaPressureRatio); 
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

                            foreach (var component in recipient.Item.Components
                                         .Where(c => c is IFluidDevice<T1, T2>)
                                         .Cast<IFluidDevice<T1, T2>>())
                            {
                                consumers.Add(component);
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