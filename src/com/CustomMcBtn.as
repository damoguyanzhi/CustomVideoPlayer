package com
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	
	/**mc按钮*/
	public class CustomMcBtn extends Sprite
	{
		private var _mc:MovieClip;
		public function CustomMcBtn(mc:MovieClip)
		{
			super();
			_mc=mc;
			_mc.gotoAndStop(1);
			this.addChild(_mc);
			
			_mc.addEventListener(MouseEvent.MOUSE_OVER,overHandler);
			_mc.addEventListener(MouseEvent.MOUSE_OUT,outhandler);
			_mc.addEventListener(MouseEvent.MOUSE_DOWN,downHandler);
		}
		
		private function overHandler(event:MouseEvent):void
		{
			_mc.gotoAndStop(2);
		}
		
		private function outhandler(event:MouseEvent):void
		{
			_mc.gotoAndStop(1);
		}
		
		private function downHandler(event:MouseEvent):void
		{
			_mc.gotoAndStop(3);
		}
	}
}