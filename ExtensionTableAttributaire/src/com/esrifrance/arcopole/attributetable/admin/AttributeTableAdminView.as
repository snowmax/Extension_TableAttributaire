package com.esrifrance.arcopole.attributetable.admin
{
	import com.esrifrance.fxfmk.components.BaseComponentAdmin;
	import com.esrifrance.fxfmk.kernel.service.IExternalLibLoader;
	
	import mx.controls.Label;
	import mx.core.IVisualElement;
	
	public class AttributeTableAdminView extends BaseComponentAdmin
	{
		public function AttributeTableAdminView()
		{
			super();
		}
		
		// Services injection.
		[Inject] public var externalModuleLoader : IExternalLibLoader;
		
		public static const componentId : String = "AttributeTable";
		
		
		
		public override function get componentCategory():String
		{
			return componentId;
		}
		
		public override function get configComponent():IVisualElement
		{
			var l:Label = new Label();
			l.horizontalCenter = 0;
			l.top = 10;
			l.text = "Configuration du composant de table attributaire";
			return l;
		}
		
		public override function createBasicConfiguration():void
		{
			super.createBasicConfiguration();
			// Add the url module in the configuration
			// This url provides the load of this external module
			var urlModule : String = externalModuleLoader.getModuleProvidingClass(AttributeTableAdminView);
			this.externalModuleLoader.writeConfigForModule(urlModule,this._configMgr);
		}
		
		[Embed("/assets/img/iTableAttributaire.png")]private var icoTable:Class;
		public override function get icon():Class
		{
			return icoTable;
		}
		
		
		public override function  get label():String 
		{
			return "Table Attributaire";
		}
	}
}