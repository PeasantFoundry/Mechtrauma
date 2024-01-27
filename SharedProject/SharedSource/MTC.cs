using Barotrauma.Items.Components;
using Barotrauma;
using Microsoft.Xna.Framework.Input.Touch;

namespace Mechtrauma
{
    public partial class MTC : ItemComponent
    {
        public MTC(Item item, ContentXElement element) : base(item, element)
        {

        }

        /* -------------------------------------------------------------------------- */
        /*                          MTC (Mechtrauma Computer)                         */
        /* -------------------------------------------------------------------------- */

        /* ------------------------------ WAITING FLAG ------------------------------ */
        //-- flags the MTC as waiting for a response
        public bool IsWaiting { get; set; }

        /* ---------------------------- WAITING FUNCTION ---------------------------- */
        //the function that terminal commands will be routed to if the MTC is waiting
        public string WaitingFunction { get; set; }

        /* ---------------------------- TRIGGER FUNCTION ---------------------------- */
        //-- the function executed by the XML trigger hook
        public string TriggerFunction { get; set; }

        /* -------------------------- IDENTIFICATION TOKEN -------------------------- */
        //-- used to diferentiate this componnent from other instances of MTC
        [Serialize("", IsPropertySaveable.No)]
        public string Token { get; set; } //
        /* ------------------------------- TOP SECRET ------------------------------- */
        //-- seriously, don't ask
        [Serialize("", IsPropertySaveable.No)]
        public string DB { get; set; } //

    }
}