package org.flixel;

import openfl.errors.Error;
import haxe.Constraints.Function;
import openfl.events.NetStatusEvent;
import openfl.net.SharedObject;
import openfl.net.SharedObjectFlushStatus;

/**
	 * A class to help automate and simplify save game functionality.
	 * Basicaly a wrapper for the Flash SharedObject thing, but
	 * handles some annoying storage request stuff too.
	 * 
	 * @author	Adam Atomic
	 */
class FlxSave
{
    private static var SUCCESS : Int = 0;
    private static var PENDING : Int = 1;
    private static var ERROR : Int = 2;
    /**
		 * Allows you to directly access the data container in the local shared object.
		 * @default null
		 */
    public var data : Dynamic;
    /**
		 * The name of the local shared object.
		 * @default null
		 */
    public var name : String;
    /**
		 * The local shared object itself.
		 * @default null
		 */
    private var _sharedObject : SharedObject;
    
    /**
		 * Internal tracker for callback function in case save takes too long.
		 */
    private var _onComplete : Function;
    /**
		 * Internal tracker for save object close request.
		 */
    private var _closeRequested : Bool;
    
    /**
		 * Blanks out the containers.
		 */
    public function new()
    {
        //super();
        destroy();
    }
    
    /**
		 * Clean up memory.
		 */
    public function destroy() : Void
    {
        _sharedObject = null;
        name = null;
        data = null;
        _onComplete = null;
        _closeRequested = false;
    }
    
    /**
		 * Automatically creates or reconnects to locally saved data.
		 * 
		 * @param	Name	The name of the object (should be the same each time to access old data).
		 * 
		 * @return	Whether or not you successfully connected to the save data.
		 */
    public function bind(Name : String) : Bool
    {
        destroy();
        name = Name;
        try
        {
            _sharedObject = SharedObject.getLocal(name);
        }
        catch (e : Error)
        {
            FlxG.log("ERROR: There was a problem binding to\nthe shared object data from FlxSave.");
            destroy();
            return false;
        }
        data = _sharedObject.data;
        return true;
    }
    
    /**
		 * A way to safely call <code>flush()</code> and <code>destroy()</code> on your save file.
		 * Will correctly handle storage size popups and all that good stuff.
		 * If you don't want to save your changes first, just call <code>destroy()</code> instead.
		 *
		 * @param	MinFileSize		If you need X amount of space for your save, specify it here.
		 * @param	OnComplete		This callback will be triggered when the data is written successfully.
		 *
		 * @return	The result of result of the <code>flush()</code> call (see below for more details).
		 */
    public function close(MinFileSize : Int = 0, OnComplete : Function = null) : Bool
    {
        _closeRequested = true;
        return flush(MinFileSize, OnComplete);
    }
    
    /**
		 * Writes the local shared object to disk immediately.  Leaves the object open in memory.
		 *
		 * @param	MinFileSize		If you need X amount of space for your save, specify it here.
		 * @param	OnComplete		This callback will be triggered when the data is written successfully.
		 *
		 * @return	Whether or not the data was written immediately.  False could be an error OR a storage request popup.
		 */
    public function flush(MinFileSize : Int = 0, OnComplete : Function = null) : Bool
    {
        if (!checkBinding())
        {
            return false;
        }
        _onComplete = OnComplete;
        var result : String = null;
        try
        {
            result = _sharedObject.flush(MinFileSize);
        }
        catch (e : Error)
        {
            return onDone(ERROR);
        }
        if (result == SharedObjectFlushStatus.PENDING)
        {
            _sharedObject.addEventListener(NetStatusEvent.NET_STATUS, onFlushStatus);
        }
        return onDone(((result == SharedObjectFlushStatus.FLUSHED)) ? SUCCESS : PENDING);
    }
    
    /**
		 * Erases everything stored in the local shared object.
		 * Data is immediately erased and the object is saved that way,
		 * so use with caution!
		 * 
		 * @return	Returns false if the save object is not bound yet.
		 */
    public function erase() : Bool
    {
        if (!checkBinding())
        {
            return false;
        }
        _sharedObject.clear();
        return true;
    }
    
    /**
		 * Event handler for special case storage requests.
		 * 
		 * @param	E	Flash net status event.
		 */
    private function onFlushStatus(E : NetStatusEvent) : Void
    {
        _sharedObject.removeEventListener(NetStatusEvent.NET_STATUS, onFlushStatus);
        onDone(((E.info.code == "SharedObject.Flush.Success")) ? SUCCESS : ERROR);
    }
    
    /**
		 * Event handler for special case storage requests.
		 * Handles logging of errors and calling of callback.
		 * 
		 * @param	Result		One of the result codes (PENDING, ERROR, or SUCCESS).
		 * 
		 * @return	Whether the operation was a success or not.
		 */
    private function onDone(Result : Int) : Bool
    {
        switch (Result)
        {
            case 1: //pending
                FlxG.log("FLIXEL: FlxSave is requesting extra storage space.");
            case 2: //error
                FlxG.log("ERROR: There was a problem flushing\nthe shared object data from FlxSave.");
            default:
        }
        if (_onComplete != null)
        {
            _onComplete(Result == SUCCESS);
        }
        if (_closeRequested)
        {
            destroy();
        }
        return Result == SUCCESS;
    }
    
    /**
		 * Handy utility function for checking and warning if the shared object is bound yet or not.
		 * 
		 * @return	Whether the shared object was bound yet.
		 */
    private function checkBinding() : Bool
    {
        if (_sharedObject == null)
        {
            FlxG.log("FLIXEL: You must call FlxSave.bind()\nbefore you can read or write data.");
            return false;
        }
        return true;
    }
}

