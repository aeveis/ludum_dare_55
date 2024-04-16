package global;


/**
 * ...
 * @author aeveis
 */
enum TextLink
{
	Repeatable;
	Oneshot;
	Triggerable(e_enableCallback:() -> Bool);
	Choices(e_choices:Array<String>, e_nodes:Array<TextNode>);
	Notify(e_callback:() -> Bool, e_node:TextNode, e_popup:Bool, e_skipCallback:() -> Bool);
}

class TextNode
{
	static public var _nodes:Array<TextNode>;

	public var texts:Array<String>;
	public var portraits:Array<String>;
	public var link:TextLink;

	public function new(p_link:TextLink = Repeatable)
	{
		texts = new Array<String>();
		portraits = new Array<String>();
		portraits.push("wiz");
		link = p_link;

		if (_nodes == null)
		{
			_nodes = new Array<TextNode>();
		}
		_nodes.push(this);
	}

	static public function destroy()
	{
		for (node in _nodes)
		{
			node.link = null;
			node.texts = null;
			node.portraits = null;
			node = null;
		}
		_nodes = null;
	}
}

class TextConstants
{
	static private var _instance:TextConstants;
	static public var instance(get, null):TextConstants;

	static public function get_instance():TextConstants
	{
		if (_instance == null)
		{
			_instance = new TextConstants();
		}
		return _instance;
	}

	static public function destroy()
	{
		TextNode.destroy();
		_instance = null;
	}

	public var debug:TextNode = new TextNode();
	public var error:TextNode = new TextNode();
	public var intro:TextNode = new TextNode();
	public var ending:TextNode = new TextNode();

	public function new()
	{
		debug.texts = ["Debug Text. <wave>This is the debug text.</wave>"];
		error.texts = ["Text ID not found. :("];
		intro.texts = [
			"<color=cyan>Phoenix Delay</color> By aeveis (dan lin) <lime>Ludum Dare 55: Summoning</lime>",
			"[ <color=yellow>Arrow keys</color> to move ]\n[ <color=yellow>X</color> to Dash ]",
			"I summon you, the great Phoenix! This will be my ultimate attack!",
			"<shake>SUMMON!!!</shake>",
			"...",
			"You better not be sleeping!!! <shake>WAKE UP!</shake>",
		];
		intro.portraits = [
			"wiz",
			"wiz",
			"wiz",
			"wiz",
			"bird",
			"wiz",
		];
		ending.texts = [
			"I summon you, the great Phoenix! This will be my ultimate attack!",
			"<red> !FOOSH! </red>",
			"Yes! It only took 123123 minutes to summon Phoenix!",
			"Thanks for playing! Press R to replay the game."
		];
		ending.portraits = [
			"wiz",
			"birdah",
			"wiz",
			"wiz",
		];
	}
}
