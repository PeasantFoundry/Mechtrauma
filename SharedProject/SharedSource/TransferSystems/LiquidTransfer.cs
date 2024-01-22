using Barotrauma;
using Barotrauma.Items.Components;

namespace Mechtrauma.TransferSystems;

public class LiquidTransfer : ItemComponent
{
    #region VARS

    private int _ticksUntilUpdate = 0;

    #endregion
    
    public LiquidTransfer(Item item, ContentXElement element) : base(item, element)
    {
    }

    public override void Update(float deltaTime, Camera cam)
    {
        base.Update(deltaTime, cam);
        _ticksUntilUpdate--;
        if (_ticksUntilUpdate < 1)
        {
            _ticksUntilUpdate = IFluidDevice.WaitTicksBetweenUpdates;
            UpdateLiquidTransfers();
        }
    }

    /// <summary>
    /// The LiquidTransfer system is stateless so producer and consumers must be built every update. This is because
    /// there isn't a graceful way to track changed/dirty item connections outside of internal vanilla code.
    /// </summary>
    private void UpdateLiquidTransfers()
    {
        IFluidDevice? producer = null;
        List<IFluidDevice> consumers = new();

        if (TryGetProducerAndConsumers())
        {
            // get liquid containers
            var producerTank = producer!.GetPrefContainerByGroup<LiquidContainer>(ILiquidData.SymbolConnOutput);
            var consumerTanks = new List<LiquidContainer>();

            // exit if no src
            if (producerTank is null)
                return;
            
            // get valid consumers
            foreach (IFluidDevice device in consumers)
            {
                foreach (var container in device.GetFluidContainersByGroup<LiquidContainer>(ILiquidData.SymbolConnInput))
                {
                    if (container.Pressure - producerTank.Pressure > float.Epsilon) // back pressure excess
                        continue;
                    if (container.GetApertureSizeForConnection(ILiquidData.SymbolConnInput) < float.Epsilon) // valve closed
                        continue;
                    consumerTanks.Add(container);
                }
            }
            
            // check if consumers can accept the fluids the producer has available
            var liquidData = producerTank.TakeFluidProportional<LiquidData>(0f);    //sample
            consumerTanks = consumerTanks.Where(c => c.CanPutFluids(liquidData)).ToList();

            // calculate fluid proportions per container.
            float sum = 0;
            foreach (var container in consumerTanks)
            {
                sum += (producerTank.Pressure - container.Pressure) * container.GetApertureSizeForConnection(ILiquidData.SymbolConnInput);
            }

            
            // send fluid to consumers
        }

        

        bool TryGetProducerAndConsumers()
        {
            bool success = false;
            try
            {
                bool foundInput = false;
                foreach (Connection connection in Item.Connections)
                {
                    if (connection.Name == ILiquidData.SymbolConnInput) // found input on self conn panel.
                    {
                        if (foundInput)
                            continue;
                        
                        foreach (Connection recipient in connection.Recipients)
                        {
                            if (foundInput)
                                break;
                            if (recipient.Name != ILiquidData.SymbolConnOutput) // we're skipping anything that isn't an liquid out connection.
                                continue;

                            foreach (ItemComponent component in recipient.Item.Components)  
                            {
                                // find the first compat IFluidDevice with an liquid out.
                                if (component is IFluidDevice { OutputPhaseType: FluidProperties.PhaseType.Liquid } device)    //outputs liquid
                                {
                                    // we found our producer.
                                    producer = device;
                                    foundInput = true;
                                    break;
                                }
                            }
                        }
                    }
                    else if (connection.Name == ILiquidData.SymbolConnOutput) // found output on self conn panel.
                    {
                        foreach (Connection recipient in connection.Recipients)
                        {
                            if (recipient.Name != ILiquidData.SymbolConnInput) // we're skipping anything that's not an input.
                                continue;

                            foreach (ItemComponent component in recipient.Item.Components)
                            {
                                if (component is IFluidDevice { InputPhaseType: FluidProperties.PhaseType.Liquid } device)
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