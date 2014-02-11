package com.esrifrance.arcopole.attributetable.client.attributetable
{
	import com.esri.ags.FeatureSet;
	import com.esri.ags.Graphic;
	import com.esri.ags.Map;
	import com.esri.ags.layers.supportClasses.LayerDetails;
	import com.esri.ags.tasks.supportClasses.Query;
	import com.esrifrance.arcopole.components.selectionmenu.events.SelectionMenuEvent;
	import com.esrifrance.fxfmk.components.ComponentInitializerHelper;
	import com.esrifrance.fxfmk.components.attributeForm.event.AttributeFormEvent;
	import com.esrifrance.fxfmk.components.attributetable.attributetable.AttributeTableEvent;
	import com.esrifrance.fxfmk.components.attributetable.attributetable.AttributeTableView;
	import com.esrifrance.fxfmk.components.attributetable.attributetable.layerlazyloader.LayerLazyLoader;
	import com.esrifrance.fxfmk.components.attributetable.attributetable.selectablegraphic.SelectableGrahic;
	import com.esrifrance.fxfmk.kernel.data.layers.AGSRestLayerRef;
	import com.esrifrance.fxfmk.kernel.data.layers.LayerRef;
	import com.esrifrance.fxfmk.kernel.data.layers.datasource.IDataSourceLayer;
	import com.esrifrance.fxfmk.kernel.event.SelectionEvent;
	import com.esrifrance.fxfmk.kernel.service.IAuthorizedMapData;
	import com.esrifrance.fxfmk.kernel.service.IComponentEventBus;
	import com.esrifrance.fxfmk.kernel.service.IConfigManager;
	import com.esrifrance.fxfmk.kernel.service.IDataTools;
	import com.esrifrance.fxfmk.kernel.service.IMapData;
	import com.esrifrance.fxfmk.kernel.service.ISelectionManager;
	import com.esrifrance.fxfmk.kernel.service.impl.ComponentEventBus;
	import com.esrifrance.fxfmk.kernel.tools.GeometryTools;
	import com.esrifrance.fxfmk.kernel.tools.LoggingUtil;
	import com.esrifrance.fxfmk.kernel.tools.SelectionTools;
	
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	
	import mx.collections.ArrayCollection;
	import mx.controls.List;
	import mx.core.mx_internal;
	import mx.events.ItemClickEvent;
	import mx.logging.ILogger;
	import mx.rpc.AsyncResponder;
	
	import spark.components.Button;
	import spark.components.DataGrid;
	import spark.components.DropDownList;
	import spark.components.RadioButtonGroup;
	import spark.components.gridClasses.GridColumn;
	import spark.components.supportClasses.Skin;
	import spark.components.supportClasses.SkinnableComponent;
	import spark.events.GridEvent;
	import spark.events.IndexChangeEvent;

	public class AttributeTableView extends SkinnableComponent
	{
		
		
		private static var _log:ILogger = LoggingUtil.getDefaultLogger(AttributeTableView);
		
		
		/// Injection des services
		
		private const _compInitializer : ComponentInitializerHelper = new ComponentInitializerHelper(this as EventDispatcher, initComponent);
		
		[Inject] public var selectionManager:ISelectionManager;
		[Inject] public var mapData:IAuthorizedMapData;
		[Inject] public var configMgr:IConfigManager;
		[Inject] public var componentEventBus:IComponentEventBus;
		
		[Inject] public var dataTools:IDataTools;
		[Inject] public var map:Map;
		
		
		public override function initialize():void
		{
			super.initialize();
			_compInitializer.watchInitialization();
		}
		
		
		//// Initialisation
		
		public function AttributeTableView()
		{
			super();
			percentHeight = 100;
			percentWidth = 100;
			this.setStyle("skinClass", AttributeTableViewSkin);
		}

		
		//// properties
		
		[Bindable]public var layerChoiceDP:ArrayCollection = new ArrayCollection();
		
		[Bindable]public var tmpLayer:LayerRef;
		
		private function initComponent():void
		{
			_log.debug("All services injected, init component");
			
			
			for each (var l:LayerRef in selectionManager.selectableLayers){
				layerChoiceDP.addItem(l);
			}
			
			selectionManager.addSelectionChangeListener(handleSelectionChange);
			
			if(tmpLayer != null) loadValuesForLayer(tmpLayer);
			
		}
		
		[Bindable] public var currentLayerRef:LayerRef;
		
		
		
		[Bindable]public var totalFeatureCount:Number = 0;
		
		private var _currentLayerLazyLoader:LayerLazyLoader;
		
		public function loadValuesForLayer(lref:LayerRef):void {
			
			this.currentLayerRef = lref;
			
			var selectionFeatureSet:FeatureSet = selectionManager.getSelection(lref as AGSRestLayerRef);
			
			var layerDetails:LayerDetails = dataTools.getLayerDetails(lref as AGSRestLayerRef);
			// = layerDetails.fields;
			
			var dataSource:IDataSourceLayer = mapData.createDataSource(lref);
						
			_currentLayerLazyLoader = new LayerLazyLoader();
			
			
			_currentLayerLazyLoader.initLazyLoader(lref,this.mapData, this.dataTools, new AsyncResponder(
				
				function(objectIds:Array, token:Object=null):void{
					totalFeatureCount = objectIds.length;
					
					
					if(_currentLayerLazyLoader.hasNext()){
						
						_currentLayerLazyLoader.next(new AsyncResponder(
							function(featureSet:FeatureSet, token:Object=null):void{
								
								attributeTable.fields = featureSet.fields;
								
								
								// performance tip : create a new source is more efficient than removeall, and no leak
								// attributeTable.selectableGraphics.removeAll();
								attributeTable.selectableGraphics.source = new Array();
								
								addAllFeaturesInTable(featureSet.features);
								
							},
							function(fault:Object, token:Object=null):void{
								
							}
						));
						
					}
						
					
					
				},
				function(fault:Object, token:Object=null):void{
					
				}
			));
		}
		
		
		
		private function attributeTableVScrollerReachBottom(e:AttributeTableEvent):void {
			
			var selectionFeatureSet:FeatureSet = selectionManager.getSelection( currentLayerRef as AGSRestLayerRef);
			
			
			var layerDetails:LayerDetails = dataTools.getLayerDetails(currentLayerRef as AGSRestLayerRef);
			
			
			if(_currentLayerLazyLoader.hasNext()){
				
				_currentLayerLazyLoader.next(new AsyncResponder(
					function(featureSet:FeatureSet, token:Object=null):void{
						
						
						addAllFeaturesInTable(featureSet.features);
						
						
						
					},
					function(fault:Object, token:Object=null):void{
						
					}
				));
				
			}
		}
		
		private var _loadingAll:Boolean = false;
		private function loadAllDataClickHandler(e:MouseEvent=null):void {
			
			if(_loadingAll)
				return;
			
			_tempFeatures = [];
			
			_loadingAll = true;
			loadAllDataR();
		}
		
		private function loadAllDataR():void {
			if(_currentLayerLazyLoader.hasNext()){
				_log.debug("Still loading");
				_currentLayerLazyLoader.next(new AsyncResponder(
					function(featureSet:FeatureSet, token:Object=null):void{
						
						_tempFeatures = _tempFeatures.concat(featureSet.features);
						
						loadAllDataR();
						
					},
					function(fault:Object, token:Object=null):void{
						
					}
				));
				
			} else {
				_log.debug("All data loaded !");
				_loadingAll = false;
				addAllFeaturesInTable(_tempFeatures);
			}
		}
		
		
		private var _tempFeatures:Array;
		
		private function addAllFeaturesInTable(features:Array):void{
			
			
			_log.debug("Try to load " + features.length + " new feature");
			
			var layerDetails:LayerDetails = dataTools.getLayerDetails(currentLayerRef as AGSRestLayerRef);
			
			
			var selectionFeatureSet:FeatureSet = selectionManager.getSelection( currentLayerRef as AGSRestLayerRef);
			var selectedIds:Array = [];
			
			for each (var selectedGraphic:Graphic in selectionFeatureSet.features){
				selectedIds.push(selectedGraphic.attributes[layerDetails.objectIdField]);
			}
			
			
			var objectIdFieldName:String = layerDetails.objectIdField;
			
			
			var selectableGraphics:Array = [];//attributeTable.selectableGraphics.toArray();
			
			for each (var g:Graphic in features){
				
				var selectableGraphic:SelectableGrahic = new SelectableGrahic();
				selectableGraphic.graphic = g;
				
				// ckeck if graphic is selected or not
				var oid:Object = g.attributes[objectIdFieldName];
				selectableGraphic.selected = false;
				for each (var sid:Object in selectedIds){
					if(sid.toString() == oid.toString()){
						selectableGraphic.selected = true;
						break;
					}
				}
				
				
				selectableGraphics.push(selectableGraphic);
			}
			
			
			//attributeTable.selectableGraphics = new ArrayCollection(selectableGraphics);
			attributeTable.selectableGraphics.addAll(new ArrayCollection(selectableGraphics));
			
		
		}
		
		
		
		////////////////////////////////////////////////////////////
		///
		///			Selection Or All 
		///
		private function selectionOrAllChangeHandler(e:ItemClickEvent):void {
			if(e.currentTarget.selectedValue == "all"){
				attributeTable.showOnlySelected = false;
			}else{
				attributeTable.showOnlySelected = true;
			}
		}
		
		
		private function handleSelectionChange(e:SelectionEvent):void{
			
			var clref:LayerRef=currentLayerRef;
			var layerDetails:LayerDetails = dataTools.getLayerDetails(clref as AGSRestLayerRef);
			if(clref != null && clref is AGSRestLayerRef){
				var selectionFeatureSet:FeatureSet = selectionManager.getSelection(clref as AGSRestLayerRef);
				
				var selectedIds:Array = [];
				for each (var selectedGraphic:Graphic in selectionFeatureSet.features){
					selectedIds.push(selectedGraphic.attributes[layerDetails.objectIdField]);
				}
				
				var objectIdFieldName:String = layerDetails.objectIdField;
				for each (var sg:SelectableGrahic in attributeTable.selectableGraphics.source){
					var searchedID:String = sg.graphic.attributes[objectIdFieldName];
					sg.selected = false;
					for each (var id:String in selectedIds){
						if( searchedID == id){
							sg.selected = true;
							break;
						}
						
					}		
				}
				
				attributeTable.selectableGraphics.refresh();
				attributeTable.validateNow();
			}
		}
		
		
		
		private function attributeTableEventSelectionChangeHandler(e:AttributeTableEvent):void {
			var selectableGraphic:SelectableGrahic = e.selectableGraphic;
			if(selectableGraphic.selected){
				_log.debug("attributeTableEventSelectionChangeHandler : select graphic " + selectableGraphic.graphic);
				selectionManager.addToSelection(currentLayerRef as AGSRestLayerRef, [selectableGraphic.graphic]);
			}else {
				_log.debug("attributeTableEventSelectionChangeHandler : unselect graphic " + selectableGraphic.graphic);
				selectionManager.removeFromSelection(currentLayerRef as AGSRestLayerRef, [selectableGraphic.graphic]);
			}
			this.componentEventBus.dispatchEvent(
				new SelectionMenuEvent(SelectionMenuEvent.SHOW_SELECTION_OR_RESULTS, SelectionMenuEvent.RESULTS_UI));
			
		}
		
		////////////////////////////////////////////////////////////
		///
		///			Zoom to All 
		///
		public function zoomToAllSelectedFeatureClickHandler(e:MouseEvent) : void 
		{
			if (this.attributeTable.selectableGraphics == null || this.attributeTable.selectableGraphics.length == 0)
				return;
			
			SelectionTools.zoomToSelection(this.map, currentLayerRef as AGSRestLayerRef, this.selectionManager);
		}
		
		
		////////////////////////////////////////////////////////////
		///
		///			Export in Excel
		///
		
		
		
		public function exportToExcelClickHandler(e:MouseEvent) : void
		{
			
			_log.debug("Exporting to Excel");
			//Prepare request
			var url:String = configMgr.applicationURL + "/exportexcel";
			
			var request:URLRequest = new URLRequest(url);
			request.method = URLRequestMethod.POST;
			request.data = new URLVariables();				
			request.data.html = getHTMLTable(this.attributeTable.attributeTableDataGrid);
			//Open window
			navigateToURL(request);				
		}
		
		private function getHTMLTable(dg:DataGrid) : String
		{
			var str:String = "<html><body><table><thead><tr>";
			// Field names
			for each (var header:GridColumn in dg.columns) {
				if(header.visible)
					str += "<td>" + header.headerText + "</td>";
			}
			str += "</tr></thead><tbody>";
			// Field values
			for each (var item:Object in dg.dataProvider) {
				str += "<tr>";
				for each (var column:GridColumn in this.attributeTable.attributeTableDataGrid.columns) {
					if(column.visible)				
						str += "<td>" + column.itemToLabel(item) + "</td>";
				}
				str += "</tr>";
			}
			str += "</tbody></table></body></html>";
			return str;
		}
		
		
		////////////////////////////////////////////////////////////
		///
		///		On over / On out / doubleclick
		///
		
		protected function resultLisDoubleClick(ev:GridEvent) : void
		{
			
			if(ev.item == null )
				return;
			
			var graphic:Graphic = (ev.item as SelectableGrahic).graphic
			
			_log.debug("Show attribute Form for graphic " + graphic);
				
			componentEventBus.dispatchEvent(new AttributeFormEvent(
				AttributeFormEvent.ATTRIBUTE_FORM_SHOW, currentLayerRef as AGSRestLayerRef, null, graphic));			
			
			// Zoom to selected item
			//SelectionTools.shiftObjectOnTheLeft(graphic, map);
			GeometryTools.zoomTo(map,graphic.geometry);
		}
		
		
		protected function resultListItemRollOver(ev:GridEvent) : void 
		{	
			if(ev.item == null || selectionOrAll.selectedValue == "all")
				return;
			SelectionTools.applyOverGraphic((ev.item as SelectableGrahic).graphic);
			
		}
	
		protected function resultListItemRollOut(ev:GridEvent) : void 
		{
			if(ev.item == null || selectionOrAll.selectedValue == "all")
				return;
			SelectionTools.applyOutGraphic((ev.item as SelectableGrahic).graphic, selectionManager);
		}
		
		
		////////////////////////////////////////////////////////////
		///
		///			LayerDropDownList 
		///
		
		
		////////////////////////////////////////////////////////////
		///
		///			PartAdded / PartRemoved
		///
		
		[SkinPart(required="true")] public var attributeTable:com.esrifrance.fxfmk.components.attributetable.attributetable.AttributeTableView;
		[SkinPart(required="true")] public var selectionOrAll:RadioButtonGroup;
		[SkinPart(required="false")] public var loadAllData:Button;
		[SkinPart(required="false")] public var zoomToAllSelectedFeature:Button;
		[SkinPart(required="false")] public var exportToExcel:Button;
		
		protected override function partAdded(partName:String, instance:Object):void {
			super.partAdded(partName, instance);
			if( selectionOrAll == instance){
				selectionOrAll.addEventListener(ItemClickEvent.ITEM_CLICK, selectionOrAllChangeHandler);
			} else if(attributeTable == instance){
				attributeTable.addEventListener(AttributeTableEvent.SELECTION_CHANGE, attributeTableEventSelectionChangeHandler);
				attributeTable.addEventListener(AttributeTableEvent.VERTICAL_SCROLLBAR_REACH_BOTTOM, attributeTableVScrollerReachBottom);
				attributeTable.attributeTableDataGrid.doubleClickEnabled = true;
				attributeTable.attributeTableDataGrid.addEventListener(GridEvent.GRID_ROLL_OVER, resultListItemRollOver);
				attributeTable.attributeTableDataGrid.addEventListener(GridEvent.GRID_ROLL_OUT, resultListItemRollOut);
				attributeTable.attributeTableDataGrid.addEventListener(GridEvent.GRID_DOUBLE_CLICK, resultLisDoubleClick);
			} else if(loadAllData == instance){
				loadAllData.addEventListener(MouseEvent.CLICK, loadAllDataClickHandler);
			} else if(zoomToAllSelectedFeature == instance){
				zoomToAllSelectedFeature.addEventListener(MouseEvent.CLICK, zoomToAllSelectedFeatureClickHandler);
			} else if(zoomToAllSelectedFeature == instance){
				zoomToAllSelectedFeature.addEventListener(MouseEvent.CLICK, zoomToAllSelectedFeatureClickHandler);
			} else if(exportToExcel == instance){
				exportToExcel.addEventListener(MouseEvent.CLICK, exportToExcelClickHandler);
			}
		}
		
		protected override function partRemoved(partName:String, instance:Object):void {
			super.partRemoved(partName, instance);
			if( selectionOrAll == instance){
				selectionOrAll.removeEventListener(ItemClickEvent.ITEM_CLICK, selectionOrAllChangeHandler);
			} else if(attributeTable == instance){
				attributeTable.removeEventListener(AttributeTableEvent.SELECTION_CHANGE, attributeTableEventSelectionChangeHandler);
				attributeTable.removeEventListener(AttributeTableEvent.VERTICAL_SCROLLBAR_REACH_BOTTOM, attributeTableVScrollerReachBottom);
				attributeTable.attributeTableDataGrid.removeEventListener(GridEvent.GRID_ROLL_OVER, resultListItemRollOver);
				attributeTable.attributeTableDataGrid.removeEventListener(GridEvent.GRID_ROLL_OUT, resultListItemRollOut);
				attributeTable.attributeTableDataGrid.removeEventListener(GridEvent.GRID_DOUBLE_CLICK, resultLisDoubleClick);
			} else if(loadAllData == instance){
				loadAllData.removeEventListener(MouseEvent.CLICK, loadAllDataClickHandler);
			} else if(zoomToAllSelectedFeature == instance){
				zoomToAllSelectedFeature.removeEventListener(MouseEvent.CLICK, zoomToAllSelectedFeatureClickHandler);
			} else if(exportToExcel == instance){
				exportToExcel.removeEventListener(MouseEvent.CLICK, exportToExcelClickHandler);
			}
		}
		
	}
}