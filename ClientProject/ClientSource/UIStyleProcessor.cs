using System.Xml.Linq;
using Barotrauma;
using Barotrauma.Extensions;

namespace Mechtrauma;

public class UIStyleProcessor : HashlessFile
{
    private ContentXElement? _element;

    public readonly Dictionary<string, GUIFont> Fonts = new();
    public readonly Dictionary<string, GUISprite> Sprites  = new();
    public readonly Dictionary<string, GUISpriteSheet> SpriteSheets = new();
    public readonly Dictionary<string, GUICursor> Cursors = new();
    public readonly Dictionary<string, GUIColor> Colors = new();
    
    private readonly UIStyleFile _fakeFile; // we literally only need this for the ctor args...

    public UIStyleProcessor(ContentPackage contentPackage, ContentPath path) : base(contentPackage, path)
    {
        _fakeFile = new UIStyleFile(contentPackage, path);
    }

    public override void LoadFile()
    {
        XDocument doc = XMLExtensions.TryLoadXml(Path);
        if (doc is null)
            return;
        _element = doc?.Root?.FromPackage(ContentPackage);
        if (_element is not null)
            LoadFromXml(_element);    
    }

    private void LoadFromXml(ContentXElement? element)
    {
        if (element is null)
            return;
        var styleElement = element.Name.LocalName.ToLowerInvariant() == "style" ? element : element.GetChildElement("style");
        if (styleElement is null)
            return; 
        
        var childElements = styleElement.GetChildElements("Font");
        if (childElements is not null)
            AddToList<GUIFont, GUIFontPrefab>(Fonts, childElements, _fakeFile);

        childElements = styleElement.GetChildElements("Sprite");
        if (childElements is not null)
            AddToList<GUISprite, GUISpritePrefab>(Sprites, childElements, _fakeFile);
        
        childElements = styleElement.GetChildElements("Spritesheet");
        if (childElements is not null)
            AddToList<GUISpriteSheet, GUISpriteSheetPrefab>(SpriteSheets, childElements, _fakeFile);
        
        childElements = styleElement.GetChildElements("Cursor");
        if (childElements is not null)
            AddToList<GUICursor, GUICursorPrefab>(Cursors, childElements, _fakeFile);
        
        childElements = styleElement.GetChildElements("Color");
        if (childElements is not null)
            AddToList<GUIColor, GUIColorPrefab>(Colors, childElements, _fakeFile);


        void AddToList<T1, T2>(Dictionary<string, T1> dict, IEnumerable<ContentXElement> ele, UIStyleFile file) where T1 : GUISelector<T2> where T2 : GUIPrefab
        {
            foreach (ContentXElement prefabElement in ele)
            {
                string name = prefabElement.GetAttributeString("name", string.Empty);
                if (name != string.Empty)
                {
                    var prefab = (T2)Activator.CreateInstance(typeof(T2), new object[]{ prefabElement, file })!;
                    if (!dict.ContainsKey(name))
                        dict[name] = (T1)Activator.CreateInstance(typeof(T1), new object[] { name })!;
                    dict[name].Prefabs.Add(prefab, false);
                }
            }
        }
    }

    public override void UnloadFile()
    {
        Fonts.Values.ForEach(p => p.Prefabs.RemoveByFile(_fakeFile));
        Sprites.Values.ForEach(p => p.Prefabs.RemoveByFile(_fakeFile));
        SpriteSheets.Values.ForEach(p => p.Prefabs.RemoveByFile(_fakeFile));
        Cursors.Values.ForEach(p => p.Prefabs.RemoveByFile(_fakeFile));
        Colors.Values.ForEach(p => p.Prefabs.RemoveByFile(_fakeFile));
    }

    public override void Sort()
    {
        Fonts.Values.ForEach(p => p.Prefabs.Sort());
        Sprites.Values.ForEach(p => p.Prefabs.Sort());
        SpriteSheets.Values.ForEach(p => p.Prefabs.Sort());
        Cursors.Values.ForEach(p => p.Prefabs.Sort());
        Colors.Values.ForEach(p => p.Prefabs.Sort());
    }
}