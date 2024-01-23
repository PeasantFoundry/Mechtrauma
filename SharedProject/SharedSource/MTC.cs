using Barotrauma.Items.Components;
using Barotrauma;

namespace Mechtrauma
{
    public partial class MTC : ItemComponent
    {
        public MTC(Item item, ContentXElement element) : base(item, element)
        {

        }

        //--- MT CLI >:)
        public bool IsWaiting { get; set; }
        public string WaitingFunction { get; set; }
        public string GoTo { get; set; }

        [Serialize("", IsPropertySaveable.No)]
        public string Token { get; set; } //
        [Serialize("", IsPropertySaveable.No)]
        public string DB { get; set; } //

    }
}