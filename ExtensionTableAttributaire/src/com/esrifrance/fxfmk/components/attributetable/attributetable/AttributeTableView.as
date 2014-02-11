package com.esrifrance.fxfmk.components.attributetable.attributetable
{
	import com.esri.ags.layers.supportClasses.Field;
	import com.esrifrance.fxfmk.components.attributetable.attributetable.selectablegraphic.BooleanGridColumnRenderer;
	import com.esrifrance.fxfmk.components.attributetable.attributetable.selectablegraphic.SelectableGrahic;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.controls.advancedDataGridClasses.AdvancedDataGridColumn;
	import mx.core.ClassFactory;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	import spark.collections.SortField;
	import spark.components.DataGrid;
	import spark.components.VScrollBar;
	import spark.components.gridClasses.GridColumn;
	import spark.components.supportClasses.SkinnableComponent;
	
	[Event(name="verticalScrollBarReachBottom", type="com.esrifrance.fxfmk.components.attributetable.attributetable.AttributeTableEvent")]
	[Event(name="selectableGraphicSelectionChange", type="com.esrifrance.fxfmk.components.attributetable.attributetable.AttributeTableEvent")]
	public class AttributeTableView extends SkinnableComponent
	{
		
		private static var _log:ILogger = Log.getLogger("com.esrifrance.fxfmk.components.attributetable.AttributeTableView");
		
		private static const _COLUMN_DEFAULT_WIDTH:Number = 150;
		private static const _SELECTION_COLUMN_DEFAULT_WIDTH:Number = 50;
		
		
		public function AttributeTableView()
		{
			super();
		}
		
		///////////////////////////////////////////////////////////////////////////
		///
		///
		///			SET FIELDS & BUILD COLUMN
		///
		///
		///////////////////////////////////////////////////////////////////////////
		
		/**
		 *	Contains the fields to display in the datagrid 
		 */
		private var _fields:Array;
		
		
		
		/**
		 *	Get an array of fields to display in the datagrid 
		 * @return an array of Field objects
		 * 
		 */
		[Bindable(event="fieldsPropertyChange")]
		public function get fields():Array{
			return _fields;
		}
		
		
		/**
		 * 
		 * @param fields an array of Field objects
		 * 
		 */
		public function set fields(fields:Array):void {
			if(fields != null){
				_log.debug("New fields has been set ! Reload datagrid colums");
				this._fields = fields;
				this.reloadDataGridColumns();
				dispatchEvent(new Event("fieldsPropertyChange"));
			}
		}
		
		
		
		/**
		 *	Reload the datagrid columns function of fields 
		 * 
		 */
		private function reloadDataGridColumns():void{
			
			_log.debug("Remove all existing columns");
			var newColumns:IList = new ArrayCollection();
			
			
			_log.debug("Add the selection columns");
			var selectiondgc:GridColumn = new GridColumn();
			selectiondgc.headerText = "";
			selectiondgc.dataField = "selected";
			selectiondgc.width = _SELECTION_COLUMN_DEFAULT_WIDTH;
			selectiondgc.itemRenderer =  new ClassFactory(BooleanGridColumnRenderer);
			newColumns.addItem(selectiondgc);
			
			_log.debug("Add fields columns");
			for each (var f:Field in this._fields){
				_log.debug("Add column for field : " + f.alias);
				var dgc:GridColumn = new GridColumn();
				dgc.headerText = f.alias;
				dgc.dataField = f.name;
				dgc.labelFunction = fieldLabelFunction;
				dgc.width = _COLUMN_DEFAULT_WIDTH;
				dgc.resizable = true;
				newColumns.addItem(dgc);
			}
			
			attributeTableDataGrid.columns = newColumns;
			attributeTableDataGrid.validateNow();
		}
		
		private function fieldLabelFunction(item:Object, column:GridColumn):String {
			if(item != null && item is SelectableGrahic){
				return (item as SelectableGrahic).graphic.attributes[column.dataField];
			}else {
				return "";
			}
		}
		
		
		///////////////////////////////////////////////////////////////////////////
		///
		///
		///			SET DATA & DATAPROVIDER
		///
		///
		///////////////////////////////////////////////////////////////////////////
		
		/**
		 *	Contains the selectable graphics to display in the datagrid 
		 */
		[Bindable] public var selectableGraphics:ArrayCollection = new ArrayCollection();
		
		
		///////////////////////////////////////////////////////////////////////////
		///
		///
		///			Vertical scrollbar event
		///
		///
		///////////////////////////////////////////////////////////////////////////
		
		private var _lastTreatValueForVScrollBar:Number = -1;
		
		private function verticalScrollbarReachBottomHandler(e:Event):void{
			var vsb:VScrollBar = e.currentTarget as VScrollBar;
			var val:Number = vsb.value;
			var max:Number = vsb.maximum;
			
			if (val > max - 10 && max != _lastTreatValueForVScrollBar && !_showOnlySelected) {
				_lastTreatValueForVScrollBar = max;
				dispatchEvent(new AttributeTableEvent(AttributeTableEvent.VERTICAL_SCROLLBAR_REACH_BOTTOM));
			}
		}
		
		
		
		///////////////////////////////////////////////////////////////////////////
		///
		///
		///			Show only selected ot all data
		///
		///
		///////////////////////////////////////////////////////////////////////////
		
		private var _showOnlySelected:Boolean = false;
		
		public function set  showOnlySelected(showOnlySelected:Boolean):void {
			if(showOnlySelected == _showOnlySelected)
				return;
			
			this._showOnlySelected = showOnlySelected;
			selectableGraphics.refresh();
			
			
		}
		
		private function filterSelectedOrNot(item:Object):Boolean {
			return !_showOnlySelected || item.selected;
		}
		
		
		
		private function attributeTableEventSelectionChangeHandler(e:AttributeTableEvent):void {
			var ev:AttributeTableEvent = new AttributeTableEvent(AttributeTableEvent.SELECTION_CHANGE);
			ev.selectableGraphic = e.selectableGraphic;
			this.dispatchEvent(ev);
		}
		
		///////////////////////////////////////////////////////////////////////////
		///
		///
		///			SKINPARTS
		///
		///
		///////////////////////////////////////////////////////////////////////////
		
		[SkinPart(required='true')]public var attributeTableDataGrid:DataGrid;
		
		
		protected override function partAdded(partName:String, instance:Object):void {
			super.partAdded(partName, instance);
			if(instance == attributeTableDataGrid){
				selectableGraphics.filterFunction = filterSelectedOrNot;
				attributeTableDataGrid.dataProvider = selectableGraphics;
				attributeTableDataGrid.scroller.verticalScrollBar.addEventListener(Event.CHANGE, verticalScrollbarReachBottomHandler);
				attributeTableDataGrid.scroller.verticalScrollBar.addEventListener(MouseEvent.MOUSE_UP, verticalScrollbarReachBottomHandler);
				attributeTableDataGrid.addEventListener(AttributeTableEvent.SELECTION_CHANGE, attributeTableEventSelectionChangeHandler);
			}
		}
		
		protected override function partRemoved(partName:String, instance:Object):void {
			super.partRemoved(partName, instance);
			if(instance == attributeTableDataGrid){
				attributeTableDataGrid.scroller.verticalScrollBar.removeEventListener(Event.CHANGE, verticalScrollbarReachBottomHandler);
				attributeTableDataGrid.scroller.verticalScrollBar.removeEventListener(MouseEvent.MOUSE_UP, verticalScrollbarReachBottomHandler);
				attributeTableDataGrid.removeEventListener(AttributeTableEvent.SELECTION_CHANGE, attributeTableEventSelectionChangeHandler);
			}
		}
		
		
		
		
		
		
	}
}