package org.flixel.system;

import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import org.flixel.FlxCamera;
import org.flixel.FlxG;
import org.flixel.FlxU;

/**
	 * A helper object to keep tilemap drawing performance decent across the new multi-camera system.
	 * Pretty much don't even have to think about this class unless you are doing some crazy hacking.
	 * 
	 * @author	Adam Atomic
	 */
class FlxTilemapBuffer
{
    public var pixels(get, never) : BitmapData;

    /**
		 * The current X position of the buffer.
		 */
    public var x : Float;
    /**
		 * The current Y position of the buffer.
		 */
    public var y : Float;
    /**
		 * The width of the buffer (usually just a few tiles wider than the camera).
		 */
    public var width : Float;
    /**
		 * The height of the buffer (usually just a few tiles taller than the camera).
		 */
    public var height : Float;
    /**
		 * Whether the buffer needs to be redrawn.
		 */
    public var dirty : Bool;
    /**
		 * How many rows of tiles fit in this buffer.
		 */
    public var rows : Int;
    /**
		 * How many columns of tiles fit in this buffer.
		 */
    public var columns : Int;
    
    private var _pixels : BitmapData;
    private var _flashRect : Rectangle;
    
    /**
		 * Instantiates a new camera-specific buffer for storing the visual tilemap data.
		 *  
		 * @param TileWidth		The width of the tiles in this tilemap.
		 * @param TileHeight	The height of the tiles in this tilemap.
		 * @param WidthInTiles	How many tiles wide the tilemap is.
		 * @param HeightInTiles	How many tiles tall the tilemap is.
		 * @param Camera		Which camera this buffer relates to.
		 */
    public function new(TileWidth : Float, TileHeight : Float, WidthInTiles : Int, HeightInTiles : Int, Camera : FlxCamera = null)
    {
        if (Camera == null)
        {
            Camera = FlxG.camera;
        }
        
        columns = as3hx.Compat.parseInt(FlxU.ceil(Camera.width / TileWidth) + 1);
        if (columns > WidthInTiles)
        {
            columns = WidthInTiles;
        }
        rows = as3hx.Compat.parseInt(FlxU.ceil(Camera.height / TileHeight) + 1);
        if (rows > HeightInTiles)
        {
            rows = HeightInTiles;
        }
        
        _pixels = new BitmapData(Std.int(columns * TileWidth), Std.int(rows * TileHeight), true, 0);
        width = _pixels.width;
        height = _pixels.height;
        _flashRect = new Rectangle(0, 0, width, height);
        dirty = true;
    }
    
    /**
		 * Clean up memory.
		 */
    public function destroy() : Void
    {
        _pixels = null;
    }
    
    /**
		 * Fill the buffer with the specified color.
		 * Default value is transparent.
		 * 
		 * @param	Color	What color to fill with, in 0xAARRGGBB hex format.
		 */
    public function fill(Color : Int = 0) : Void
    {
        _pixels.fillRect(_flashRect, Color);
    }
    
    /**
		 * Read-only, nab the actual buffer <code>BitmapData</code> object.
		 * 
		 * @return	The buffer bitmap data.
		 */
    private function get_pixels() : BitmapData
    {
        return _pixels;
    }
    
    /**
		 * Just stamps this buffer onto the specified camera at the specified location.
		 * 
		 * @param	Camera		Which camera to draw the buffer onto.
		 * @param	FlashPoint	Where to draw the buffer at in camera coordinates.
		 */
    public function draw(Camera : FlxCamera, FlashPoint : Point) : Void
    {
        Camera.buffer.copyPixels(_pixels, _flashRect, FlashPoint, null, null, true);
    }
}
