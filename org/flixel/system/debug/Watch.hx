package org.flixel.system.debug;

import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFormat;
import org.flixel.FlxU;
import org.flixel.system.FlxWindow;

/**
	 * A Visual Studio-style "watch" window, for use in the debugger overlay.
	 * Track the values of any public variable in real-time, and/or edit their values on the fly.
	 * 
	 * @author Adam Atomic
	 */
class Watch extends FlxWindow
{
    private static inline var MAX_LOG_LINES : Int = 1024;
    private static inline var LINE_HEIGHT : Int = 15;
    
    /**
		 * Whether a watch entry is currently being edited or not. 
		 */
    public var editing : Bool;
    
    private var _names : Sprite;
    private var _values : Sprite;
    private var _watching : Array<Dynamic>;
    
    /**
		 * Creates a new window object.  This Flash-based class is mainly (only?) used by <code>FlxDebugger</code>.
		 * 
		 * @param Title			The name of the window, displayed in the header bar.
		 * @param Width			The initial width of the window.
		 * @param Height		The initial height of the window.
		 * @param Resizable		Whether you can change the size of the window with a drag handle.
		 * @param Bounds		A rectangle indicating the valid screen area for the window.
		 * @param BGColor		What color the window background should be, default is gray and transparent.
		 * @param TopColor		What color the window header bar should be, default is black and transparent.
		 */
    public function new(Title : String, Width : Float, Height : Float, Resizable : Bool = true, Bounds : Rectangle = null, BGColor : Int = 0x7f7f7f7f, TopColor : Int = 0x7f000000)
    {
        super(Title, Width, Height, Resizable, Bounds, BGColor, TopColor);
        
        _names = new Sprite();
        _names.x = 2;
        _names.y = 15;
        addChild(_names);
        
        _values = new Sprite();
        _values.x = 2;
        _values.y = 15;
        addChild(_values);
        
        _watching = new Array<Dynamic>();
        
        editing = false;
        
        removeAll();
    }
    
    /**
		 * Clean up memory.
		 */
    override public function destroy() : Void
    {
        removeChild(_names);
        _names = null;
        removeChild(_values);
        _values = null;
        var i : Int = 0;
        var l : Int = _watching.length;
        while (i < l)
        {
            (try cast(_watching[i++], WatchEntry) catch(e:Dynamic) null).destroy();
        }
        _watching = null;
        super.destroy();
    }
    
    /**
		 * Add a new variable to the watch window.
		 * Has some simple code in place to prevent
		 * accidentally watching the same variable twice.
		 * 
		 * @param AnyObject		The <code>Object</code> containing the variable you want to track, e.g. this or Player.velocity.
		 * @param VariableName	The <code>String</code> name of the variable you want to track, e.g. "width" or "x".
		 * @param DisplayName	Optional <code>String</code> that can be displayed in the watch window instead of the basic class-name information.
		 */
    public function add(AnyObject : Dynamic, VariableName : String, DisplayName : String = null) : Void
    //Don't add repeats
    {
        
        var watchEntry : WatchEntry;
        var i : Int = 0;
        var l : Int = _watching.length;
        while (i < l)
        {
            watchEntry = try cast(_watching[i++], WatchEntry) catch(e:Dynamic) null;
            if ((watchEntry.object == AnyObject) && (watchEntry.field == VariableName))
            {
                return;
            }
        }
        
        //Good, no repeats, add away!
        watchEntry = new WatchEntry(_watching.length * LINE_HEIGHT, _width / 2, _width / 2 - 10, AnyObject, VariableName, DisplayName);
        _names.addChild(watchEntry.nameDisplay);
        _values.addChild(watchEntry.valueDisplay);
        _watching.push(watchEntry);
    }
    
    /**
		 * Remove a variable from the watch window.
		 * 
		 * @param AnyObject		The <code>Object</code> containing the variable you want to remove, e.g. this or Player.velocity.
		 * @param VariableName	The <code>String</code> name of the variable you want to remove, e.g. "width" or "x".  If left null, this will remove all variables of that object. 
		 */
    public function remove(AnyObject : Dynamic, VariableName : String = null) : Void
    //splice out the requested object
    {
        
        var watchEntry : WatchEntry;
        var i : Int = as3hx.Compat.parseInt(_watching.length - 1);
        while (i >= 0)
        {
            watchEntry = _watching[i];
            if ((watchEntry.object == AnyObject) && ((VariableName == null) || (watchEntry.field == VariableName)))
            {
                _watching.splice(i, 1);
                _names.removeChild(watchEntry.nameDisplay);
                _values.removeChild(watchEntry.valueDisplay);
                watchEntry.destroy();
            }
            i--;
        }
        watchEntry = null;
        
        //reset the display heights of the remaining objects
        i = 0;
        var l : Int = _watching.length;
        while (i < l)
        {
            (try cast(_watching[i], WatchEntry) catch(e:Dynamic) null).setY(i * LINE_HEIGHT);
            i++;
        }
    }
    
    /**
		 * Remove everything from the watch window.
		 */
    public function removeAll() : Void
    {
        var watchEntry : WatchEntry;
        var i : Int = 0;
        var l : Int = _watching.length;
        while (i < l)
        {
            watchEntry = _watching.pop();
            _names.removeChild(watchEntry.nameDisplay);
            _values.removeChild(watchEntry.valueDisplay);
            watchEntry.destroy();
            i++;
        }
        as3hx.Compat.setArrayLength(_watching, 0);
    }
    
    /**
		 * Update all the entries in the watch window.
		 */
    public function update() : Void
    {
        editing = false;
        var i : Int = 0;
        var l : Int = _watching.length;
        while (i < l)
        {
            if (!(try cast(_watching[i++], WatchEntry) catch(e:Dynamic) null).updateValue())
            {
                editing = true;
            }
        }
    }
    
    /**
		 * Force any watch entries currently being edited to submit their changes.
		 */
    public function submit() : Void
    {
        var i : Int = 0;
        var l : Int = _watching.length;
        var watchEntry : WatchEntry;
        while (i < l)
        {
            watchEntry = try cast(_watching[i++], WatchEntry) catch(e:Dynamic) null;
            if (watchEntry.editing)
            {
                watchEntry.submit();
            }
        }
        editing = false;
    }
    
    /**
		 * Update the Flash shapes to match the new size, and reposition the header, shadow, and handle accordingly.
		 * Also adjusts the width of the entries and stuff, and makes sure there is room for all the entries.
		 */
    override private function updateSize() : Void
    {
        if (_height < _watching.length * LINE_HEIGHT + 17)
        {
            _height = _watching.length * LINE_HEIGHT + 17;
        }
        
        super.updateSize();
        
        _values.x = _width / 2 + 2;
        
        var i : Int = 0;
        var l : Int = _watching.length;
        while (i < l)
        {
            (try cast(_watching[i++], WatchEntry) catch(e:Dynamic) null).updateWidth(_width / 2, _width / 2 - 10);
        }
    }
}

