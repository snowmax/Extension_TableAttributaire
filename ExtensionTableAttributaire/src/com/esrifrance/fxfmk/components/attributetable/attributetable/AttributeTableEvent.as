package com.esrifrance.fxfmk.components.attributetable.attributetable
{
	import com.esrifrance.fxfmk.components.attributetable.attributetable.selectablegraphic.SelectableGrahic;
	
	import flash.events.Event;
	
	public class AttributeTableEvent extends Event
	{
		
		public static const VERTICAL_SCROLLBAR_REACH_BOTTOM:String = "verticalScrollBarReachBottom";
		
		
		public static const SELECTION_CHANGE:String = "selectableGraphicSelectionChange";
		
		
		[Bindable]public var selectableGraphic:SelectableGrahic;
		
		public function AttributeTableEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}