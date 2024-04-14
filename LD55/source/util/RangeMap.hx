package util;

/**
 * ...
 * @author aeveis
 */
class RangeMap <V>
{
    public var value:V;
    public var keys:Array<Float>;
    public var values:Array<V>;

    public function new()
    {
        keys = new Array<Float>();
        values = new Array<V>();
    }

    public function set(key:Float, value:V)
    {
        if(!keys.contains(key))
        {
            keys.push(key);
            keys.sort((x,y)->{return Math.floor(x*1000-y*1000);});
        }
        values[keys.indexOf(key)] = value;
    }

    public function get(key:Float, epsilon:Float = 0.0000001):Null<V>
    {
        for(i in 0...keys.length)
        {
            if(keys[i] >= key - epsilon && keys[i] <= key + epsilon)
            {
                return values[i];
            }
        }
        return null;
    }

    public function getFirstGreater(key:Float, range:Float = 1.0):Null<V>
    {
        for(i in 0...keys.length)
        {
            if(keys[i] >= key && keys[i] - range <= key)
            {
                return values[i];
            }
        }
        return null;
    }

    public function getFirstLess(key:Float, range:Float = 1.0):Null<V>
    {
        for(i in 0...keys.length)
        {
            if(keys[i] <= key && keys[i] + range >= key)
            {
                return values[i];
            }
        }
        return null;
    }

    public function getAllGreater(key:Float, range:Float = 1.0):Array<V>
    {
        var match = new Array<V>();
        for(i in 0...keys.length)
        {
            if(keys[i] >= key && keys[i] - range <= key)
            {
                match.push(values[i]);
            }
        }
        return match;
    }

    public function getAllLess(key:Float, range:Float = 1.0):Array<V>
    {
        var match = new Array<V>();
        for(i in 0...keys.length)
        {
            if(keys[i] <= key && keys[i] + range >= key)
            {
                match.push(values[i]);
            }
        }
        return match;
    }

    public function exists(key:Float):Bool
    {
        return keys.contains(key);
    }

    public function existsGreater(key:Float, range:Float = 1.0):Bool
        {
            for(i in 0...keys.length)
            {
                if(keys[i] >= key && keys[i] - range <= key)
                {
                    return true;
                }
            }
            return false;
        }
    
        public function existsLess(key:Float, range:Float = 1.0):Bool
        {
            for(i in 0...keys.length)
            {
                if(keys[i] <= key && keys[i] + range >= key)
                {
                    return  true;
                }
            }
            return false;
        }
    
    public function remove(key:Float):Bool
    {
        if(!keys.contains(key))
        {
            return false;
        }
        values.remove(values[keys.indexOf(key)]);
        keys.remove(key);
        return true;
    }

    public function clear():Void
    {
        while (keys.length > 0)
        {
            values.pop();
            keys.pop();
        }
    }

}