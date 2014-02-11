package com.esrifrance.fxfmk.components.attributetable.attributetable.selectablegraphic
{
	import com.esri.ags.Graphic;

	public class SelectableGrahic
	{
		public function SelectableGrahic()
		{
		}
		
		
		[Bindable]public  var graphic:Graphic;
		[Bindable]public  var selected:Boolean;
		
		
	}
}