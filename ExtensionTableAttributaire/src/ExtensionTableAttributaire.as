package
{
	import com.esrifrance.arcopole.attributetable.admin.AttributeTableAdminView;
	import com.esrifrance.arcopole.attributetable.client.AttributeTableClientView;
	import com.esrifrance.fxfmk.kernel.data.modules.IExternalModule;
	
	import mx.modules.Module;
	
	public class ExtensionTableAttributaire extends Module implements IExternalModule
	{
		public function ExtensionTableAttributaire()
		{
			super();
		}
		
		public function get classesToLoad():Vector.<Class>
		{
			var v:Vector.<Class> = new Vector.<Class>();
			v.push(AttributeTableAdminView);
			v.push(AttributeTableClientView);
			return v;
		}
	}
}