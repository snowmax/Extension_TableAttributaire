package com.esrifrance.fxfmk.components.attributetable.attributetable.layerlazyloader
{
	import com.esri.ags.FeatureSet;
	import com.esri.ags.layers.Layer;
	import com.esri.ags.layers.supportClasses.Field;
	import com.esri.ags.tasks.QueryTask;
	import com.esri.ags.tasks.supportClasses.Query;
	import com.esrifrance.fxfmk.components.ComponentInitializerHelper;
	import com.esrifrance.fxfmk.kernel.data.layers.AGSRestLayerRef;
	import com.esrifrance.fxfmk.kernel.data.layers.LayerRef;
	import com.esrifrance.fxfmk.kernel.data.layers.datasource.IDataSourceLayer;
	import com.esrifrance.fxfmk.kernel.service.IAuthorizedMapData;
	import com.esrifrance.fxfmk.kernel.service.IDataTools;
	import com.esrifrance.fxfmk.kernel.service.impl.DataSourceFactory;
	import com.esrifrance.fxfmk.kernel.tools.LoggingUtil;
	
	import flash.events.EventDispatcher;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.rpc.AsyncResponder;

	public class LayerLazyLoader extends EventDispatcher implements ILayerLazyLoader
	{
		public function LayerLazyLoader()
		{
		}
	
		private static var _log:ILogger = LoggingUtil.getDefaultLogger(LayerLazyLoader);
		
		private static const _DEFAULT_MAX_FEATURE_COUNT:Number = 1000;
		
		
		private var _mapData:IAuthorizedMapData;
		
		private var _dataTools:IDataTools;
		
		private var _maxFeatureReturnCount:Number;
		
		private var _lastFeatureIndex:Number = 0;
		
		private var _layerRef:LayerRef;
		
		private var _datasource:IDataSourceLayer;
		
		private var _sortedIds:Array;
		
		
		private var _queryTask:QueryTask;
		
		private var _alreadyInit:Boolean = false;
		
		public function get maxFeatureReturnCount():Number {
			return _maxFeatureReturnCount;
		}
		
		
		public function initLazyLoader(lref:LayerRef, mapData:IAuthorizedMapData,  dataTools:IDataTools,async:AsyncResponder, maxFeatureReturnCount:Number=_DEFAULT_MAX_FEATURE_COUNT):void {
			
			this._layerRef = lref;
			this._mapData = mapData;
			this._datasource =  _mapData.createDataSource(lref) as IDataSourceLayer;
			this._maxFeatureReturnCount = maxFeatureReturnCount;
			this._dataTools = dataTools;
			
			// ask for ids
			if(_sortedIds != null){
				async.result(_sortedIds);
				return;
			}
			
			// create a query
			var q:Query = new Query();
			q.returnGeometry = false;
			q.where = "1=1";
			
			// create a querytask
			var url:String = _datasource.getUrl();
			_queryTask = new QueryTask(url);
			_queryTask.useAMF = false;
			_queryTask.showBusyCursor = true;
			_queryTask.token = _datasource.getToken();
			
			
			_log.debug("Execute for ids query on layer " + url);
			_queryTask.executeForIds(q, new AsyncResponder(onResultExecuteForIds, onFaultExecuteForIds, url));
			
			function onResultExecuteForIds(result:Array, token:Object = null):void
			{
				_log.debug("Execute query for ids on " + token.toString() + " sucess. Return " + result.length + " ids")
				_sortedIds = result.sort(Array.NUMERIC);
				_alreadyInit = true;
				async.result(_sortedIds);
			}
			
			function onFaultExecuteForIds(info:Object, token:Object = null):void
			{
				_log.warn("Execute query for ids on " + token.toString() + " failed ! " + info.toString())
 				async.fault(info);
			}
			
		}
		
		public function get featureCount():Number {
			if(!_alreadyInit){
				_log.error("Call featureCount() function before calling init(). Can't return data");
				return -1;
			}
			return this._sortedIds.length;
		}
		
		public function get featureIds():Array {
			if(!_alreadyInit){
				_log.error("Call featureIds() function before calling init(). Can't return data");
				return null;
			}
			return this._sortedIds;
		}
		
		
		public function next(async:AsyncResponder):void{
			
			
			if(!_alreadyInit){
				_log.error("Call next() function before calling init(). Can't return data");
				return;
			}
			
			var q:Query = new Query();
			q.returnGeometry = true;
			q.where = "1=1";
			
			var fields:Array = [];
			for each(var f:Field in  _dataTools.getFields(this._layerRef as AGSRestLayerRef)){
				
				if(f.type != Field.TYPE_GEOMETRY)
					fields.push(f.name);
				
			}
			q.outFields = fields;
			
			
			
			
			_log.debug("Check if we need a part of objectids");
			if(featureCount < this._maxFeatureReturnCount)
			{
				_log.debug("Number of feature is less than max return capacity : return all object ids");
				q.objectIds = this._sortedIds;
			}
			else {
				_log.debug("Number of feature is more than max return capacity : return a part of object ids ("+this._lastFeatureIndex +"-"+(this._lastFeatureIndex + this._maxFeatureReturnCount)+")");
				q.objectIds = this._sortedIds.slice(this._lastFeatureIndex, this._lastFeatureIndex + this._maxFeatureReturnCount);
			}
			
			_log.debug("Execute query on layer " + _queryTask.url);
			
			_queryTask.execute(q, new AsyncResponder(onResultExecute, onFaultExecute, _queryTask.url));
			
			function onResultExecute(featureSet:FeatureSet, token:Object = null):void
			{
				
				
				var numberOfFeatureReturn:Number = featureSet.features.length;
				_log.debug("Execute query on layer " + _queryTask.url + " sucess with " +numberOfFeatureReturn+" features return" );
				
				_lastFeatureIndex = _lastFeatureIndex + numberOfFeatureReturn;
				
				// check if _maxFeatureReturnCount is not too big
				if( numberOfFeatureReturn < _maxFeatureReturnCount){
					_log.info(" Max feature return count was too big " + _maxFeatureReturnCount + " -> " + numberOfFeatureReturn);	
					_maxFeatureReturnCount = numberOfFeatureReturn;
				}
				
				async.result(featureSet);
			}
			
			function onFaultExecute(info:Object, token:Object = null):void
			{
				_log.warn("Execute query f on " + token.toString() + " failed ! " + info.toString())
				async.fault(info);
			}
			
			
		}
		
		public function hasNext():Boolean {
			if(!_alreadyInit){
				_log.error("Call hasNext() function before calling init(). Can't return data");
				return false;
			}
			return _lastFeatureIndex < featureCount;
		}
		
	
	}
}
