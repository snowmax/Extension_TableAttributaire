package com.esrifrance.fxfmk.components.attributetable.attributetable.layerlazyloader
{
	import com.esrifrance.fxfmk.kernel.data.layers.LayerRef;
	import com.esrifrance.fxfmk.kernel.service.IAuthorizedMapData;
	import com.esrifrance.fxfmk.kernel.service.IDataTools;
	
	import mx.rpc.AsyncResponder;

	/**
	 *
	 * 
	 *  
	 * @author GLM
	 * 
	 */
	public interface ILayerLazyLoader
	{
		
		
		/**
		 * Init the lazyloader object (query for ids & sort them)
		 * 
		 * @param lref The layer reference that contains data to load
		 * 
		 * @param mapData A reference to the authorizedmapData service to create datasource & check fo fields rights
		 * 
		 * @param async An async Responder to get The response <br/>
		 * 			<code>function(objectIds:Array, token:Object=null):void</code><br/>
		 * 			<code>function(fault:Object, token:Object=null):void</code>
		 *
		 * @param the maximum feature that your Arcgis Server can return by query (default is 1000)
		 * 
		 */
		function initLazyLoader(lref:LayerRef,  mapData:IAuthorizedMapData, dataTools:IDataTools, async:AsyncResponder, maxFeatureReturnCount:Number=1000):void;
		
		
		
		/**
		 * FeatureIds accessor 
		 * @return An array of all the features objectid sorted
		 * 
		 */
		function get featureIds():Array;
		
		/**
		 * Feature Count 
		 * @return The number of feature in the table
		 * 
		 */
		function get featureCount():Number;
		
		/**
		 * Tell if we have load all the data
		 * @return if there is more data or not
		 * 
		 */
		function hasNext():Boolean;
		
		/**
		 * Get the next featureSet in the limit of  
		 * @param async
		 * 
		 */
		function next(async:AsyncResponder):void;
		
		/**
		 * Accessor to the  <code>maxFeatureReturnCount<property>
		 * @return  the maximum feature that your Arcgis Server can return by query (default is 1000) 
		 * 
		 */
		function get maxFeatureReturnCount():Number;

		
	}
}