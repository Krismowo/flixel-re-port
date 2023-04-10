package org.flixel.plugin;

import org.flixel.*;

/**
	 * A simple manager for tracking and updating game timer objects.
	 * 
	 * @author	Adam Atomic
	 */
class TimerManager extends FlxBasic
{
    private var _timers : Array<Dynamic>;
    
    /**
		 * Instantiates a new timer manager.
		 */
    public function new()
    {
        super();
        _timers = new Array<Dynamic>();
        visible = false;
    }
    
    /**
		 * Clean up memory.
		 */
    override public function destroy() : Void
    {
        clear();
        _timers = null;
    }
    
    /**
		 * Called by <code>FlxG.updatePlugins()</code> before the game state has been updated.
		 * Cycles through timers and calls <code>update()</code> on each one.
		 */
    override public function update() : Void
    {
        var i : Int = as3hx.Compat.parseInt(_timers.length - 1);
        var timer : FlxTimer;
        while (i >= 0)
        {
            timer = try cast(_timers[i--], FlxTimer) catch(e:Dynamic) null;
            if ((timer != null) && !timer.paused && !timer.finished && (timer.time > 0))
            {
                timer.update();
            }
        }
    }
    
    /**
		 * Add a new timer to the timer manager.
		 * Usually called automatically by <code>FlxTimer</code>'s constructor.
		 * 
		 * @param	Timer	The <code>FlxTimer</code> you want to add to the manager.
		 */
    public function add(Timer : FlxTimer) : Void
    {
        _timers.push(Timer);
    }
    
    /**
		 * Remove a timer from the timer manager.
		 * Usually called automatically by <code>FlxTimer</code>'s <code>stop()</code> function.
		 * 
		 * @param	Timer	The <code>FlxTimer</code> you want to remove from the manager.
		 */
    public function remove(Timer : FlxTimer) : Void
    {
        var index : Int = Lambda.indexOf(_timers, Timer);
        if (index >= 0)
        {
            _timers.splice(index, 1);
        }
    }
    
    /**
		 * Removes all the timers from the timer manager.
		 */
    public function clear() : Void
    {
        var i : Int = as3hx.Compat.parseInt(_timers.length - 1);
        var timer : FlxTimer;
        while (i >= 0)
        {
            timer = try cast(_timers[i--], FlxTimer) catch(e:Dynamic) null;
            if (timer != null)
            {
                timer.destroy();
            }
        }
        as3hx.Compat.setArrayLength(_timers, 0);
    }
}
