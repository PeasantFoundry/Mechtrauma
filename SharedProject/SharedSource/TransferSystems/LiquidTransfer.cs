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
            // get apertures, pressures at consumers
            // calculate proportions
            // calculate max volume transfer based on combined min aperture * velocity at producer
            // set values of fluid transfer struct
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

            return success && producer is not null && consumers.Any();
        }

        void ProcessTransfers()
        {
            
        }
    }
}