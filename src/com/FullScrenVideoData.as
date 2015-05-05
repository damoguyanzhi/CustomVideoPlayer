package com
{
	/**全屏时的播放数据*/
	public class FullScrenVideoData
	{
		public var videoType:int;//1是否正常 2为独立全屏
		public var url:String;
		public var w:int;
		public var h:int;
		/**当前播放头按钮位置 */
		public var curPlayMoveBtnX:int;
		/**当前播放进度 */
		public var curPlayPos:Number;
		public var isPause:Boolean;//是否暂停
		/**声音头按钮位置*/
		public var curVolumeBtnX:Number;
		/**当前音量*/
		public var volumeValue:Number;
		public var isVolumeStatic:Boolean;//是否静止声音
		public var video:MyVideo;
	}
}