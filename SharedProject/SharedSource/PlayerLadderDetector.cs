using Barotrauma;
using Barotrauma.Items.Components;

namespace Mechtrauma;

public partial class PlayerLadderDetector : ItemComponent
{

    public static readonly string EVENT_ONVALUEUPDATE = "Mechtrauma.PlayerLadderDetector::OnLadderValueUpdate"; //args: this, Character
    
    [Editable(0, 120), Serialize(15, IsPropertySaveable.No, "Wait time in ticks between checks")]
    public int WaitTimeBetweenUpdates { get; set; }

    private int _updateWaitTicksRemaining;

    private Character? _foundCharacter;
    public bool IsOnLadder { get; protected set; }
    
    public PlayerLadderDetector(Item item, ContentXElement element) : base(item, element)
    {
        IsActive = true;
    }

    private partial void Synchronize();

    public override void Update(float deltaTime, Camera cam)
    {
        base.Update(deltaTime, cam);
        _updateWaitTicksRemaining--;
        if (_updateWaitTicksRemaining < 1)
        {
            _updateWaitTicksRemaining = Math.Max(0, WaitTimeBetweenUpdates);
            UpdateChecks();
            Synchronize();
        }
    }

    protected virtual void TriggerHooks()
    {
        GameMain.LuaCs.Hook.Call(EVENT_ONVALUEUPDATE, this, _foundCharacter);
    }

    protected virtual void UpdateChecks()
    {
        if (item.GetRootInventoryOwner() is Character { IsPlayer: true } ownerChar)
        {
            IsOnLadder = ownerChar.SelectedItem.GetComponent<Ladder>() is { };
            _foundCharacter = ownerChar;
        }
        else
        {
            IsOnLadder = false;
            _foundCharacter = null;
        }
    }
}