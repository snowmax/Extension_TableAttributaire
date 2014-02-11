package com.esrifrance.arcopole.attributetable.client
{

	import com.esrifrance.arcopole.attributetable.client.attributetable.AttributeTableView;
	import com.esrifrance.arcopole.components.window.ResizableTitleWindow;
	import com.esrifrance.arcopole.components.window.ResizableTitleWindowSkin;
	import com.esrifrance.arcopole.extensions.client.ArcopoleComponentContainerTypes;
	import com.esrifrance.arcopole.extensions.client.IArcopoleComponent;
	import com.esrifrance.fxfmk.components.ComponentInitializerHelper;
	import com.esrifrance.fxfmk.components.layerlisttoolbar.events.LayerListToolbarEvent;
	import com.esrifrance.fxfmk.components.layerlisttoolbar.events.SelectionLayerChangeEvent;
	import com.esrifrance.fxfmk.kernel.data.layers.LayerRef;
	import com.esrifrance.fxfmk.kernel.event.ActiveLayerEvent;
	import com.esrifrance.fxfmk.kernel.service.IComponentEventBus;
	import com.esrifrance.fxfmk.kernel.service.IMapManager;
	import com.esrifrance.fxfmk.kernel.service.ISelectionManager;
	import com.esrifrance.fxfmk.kernel.tools.LoggingUtil;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	
	import mx.core.FlexGlobals;
	import mx.events.CloseEvent;
	import mx.logging.ILogger;
	import mx.managers.PopUpManager;
	
	import spark.components.TitleWindow;
	import spark.components.supportClasses.ButtonBase;
	import spark.components.supportClasses.SkinnableComponent;
	
	public class AttributeTableClientView extends SkinnableComponent implements IArcopoleComponent
	{
		
		private const _compInitializer : ComponentInitializerHelper = new ComponentInitializerHelper(this as EventDispatcher, initComponent);
		
		[Inject] public var componentEventBus:IComponentEventBus;
		
		[Inject] public var mapManager:IMapManager;
		[Inject] public var selectionManager:ISelectionManager;
		
		private static var _log:ILogger = LoggingUtil.getDefaultLogger(AttributeTableClientView); 
		
		//private var popuprend:PopUpRenderer = new PopUpRenderer();
		
		[Embed(source="/assets/img/liste.png")]public var icoTA:Class;
		
		
		public function AttributeTableClientView()
		{
			_log.debug("creation of AttributeTableClientView");
			
			this.visible = true;
			this.width =0;
			this.height = 0;
			this.x = 0;
			this.y = 0;
			this.setStyle("skinClass", AttributeTableClientViewSkin);
		}
		
		public override function initialize():void
		{
			super.initialize();
			_compInitializer.watchInitialization();
		}
		
		public function get containerType():String
		{
			return ArcopoleComponentContainerTypes.ABSOLUTE;
		}
		
		private function initComponent():void
		{
		
			componentEventBus.addEventListener("ShowAttributeTableForCurrentLayerRef", showAttributeTableEventHandler);
			//componentEventBus.addEventListener(SelectionLayerChangeEvent.selectionLayerChangedEventName, handleSelectionLayerChange);
			mapManager.addActiveLayerChangeListener(handleActiveLayerChange);
			
			showAttributeTableEventHandler(null);
		}
		
		
		private var _tmpActiveLayer:LayerRef;
		
		private function handleActiveLayerChange(e:ActiveLayerEvent):void{
			_tmpActiveLayer = e.layer; 
			if(attributeTableView != null){
				attributeTableView.loadValuesForLayer(e.layer);
			}
		}
		
		//////////////////
		//
		//		Big Button
		//
		/////////////////
		
		private var popup:ResizableTitleWindow;
		private var attributeTableView:AttributeTableView;
		
		public function showAttributeTableEventHandler(e:Event):void {
			
			if(popup == null) {
			
			
				_log.debug("Click on big Attribute Table button : create popup");
				var popup:ResizableTitleWindow = PopUpManager.createPopUp(FlexGlobals.topLevelApplication as DisplayObject, ResizableTitleWindow) as ResizableTitleWindow;
				
				attributeTableView = new AttributeTableView();
				attributeTableView.tmpLayer = this._tmpActiveLayer;
				
				popup.icon = icoTA;
				popup.contentGroup.addElement(attributeTableView);
				popup.title = "Table attributaire";
				popup.minWidth = 400;
				popup.minHeight = 400;
				popup.maxWidth = 1000;
				PopUpManager.centerPopUp(popup);
			
			}
			
			popup.addEventListener(CloseEvent.CLOSE, function(e:CloseEvent):void {PopUpManager.removePopUp(popup);});
			
		}
		
		
	}
}