using Barotrauma;

namespace Mechtrauma;

public sealed class MTEvents
{
    #region INSTVARS

    private readonly Dictionary<string, Dictionary<string, System.Action<object[]>>> _eventsCallback = new ();
    private static MTEvents? _instance;
    
    #endregion

    #region PUBLIC_API

    public static MTEvents Instance
    {
        get
        {
            if (_instance is null)
                _instance = new();
            return _instance;
        }
    }

    public void SendEventLocal(string eventName, params object[] args)
    {
        if (!_eventsCallback.ContainsKey(eventName))
            return;
        if (_eventsCallback[eventName] is null || _eventsCallback[eventName].Count < 1)
            return;
        foreach (var action in _eventsCallback[eventName])
        {
            try
            {
                action.Value?.Invoke(args);
            }
            catch
            {
                continue;
            }
        }
    }

    public void Subscribe(string eventName, string callbackName, System.Action<object[]> callback)
    {
        if (!_eventsCallback.ContainsKey(eventName))
            _eventsCallback[eventName] = new Dictionary<string, Action<object[]>>();
        if (_eventsCallback[eventName].ContainsKey(callbackName))
        {
            ModUtils.Logging.PrintError($"Warning: Event Callback {eventName} already contains a registered member named {callbackName}. Please use a different ID. Skipping.");
            return;
        }
        _eventsCallback[eventName].Add(callbackName, callback);
    }

    public void Unsubscribe(string eventName, string callbackName)
    {
        if (!_eventsCallback.ContainsKey(eventName))
            return;
        if (_eventsCallback[eventName] is null || _eventsCallback[eventName].Count < 1)
            return;
        _eventsCallback[eventName].Remove(callbackName);
    }

    #endregion
}