package util;

class SpawnFloat
{
    public var value:Float = 0;
    public var spawned:Bool = false;
    public var dead:Bool = false;
	public var despawnX:Float = 0;

    public function new(pvalue:Float, pspawned:Bool = false)
    {
        value = pvalue;
        spawned = pspawned;
    }

}