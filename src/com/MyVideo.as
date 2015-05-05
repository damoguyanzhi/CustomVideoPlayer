package com
{
	import flash.display.Sprite;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.NetStatusEvent;
	import flash.geom.Rectangle;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	/**视频播放器*/
	public class MyVideo extends Sprite
	{
		private var _netStream:NetStream;
		private var _netConnection:NetConnection;
		private var _video:Video;
		private var isPause:Boolean = false;
		private var IsHiter:Boolean = false;
		private var mySoundTransform:SoundTransform =new SoundTransform();
		private var _duration:Number;
		private var volume_Rectangle:Rectangle;
		private var play_Rectangle:Rectangle;
		private var p:Boolean=true;
		private var _status:String;
		private var _playBtn:CustomMcBtn;
		private var _pauseBtn:CustomMcBtn;
		/**播放头按钮*/
		private var _playMoveBtn:PlayMovBtn;
		/**声音头按钮*/
		private var _volumeBtn:PlayMovBtn;
		/**控制关闭声音*/
		private var _soundControllerMc:SoundControllerMc;
		private var _volumeMc:VolumeMc;
		private var _playMc:PlayMc;
		private var _playBarBg:PlayBarBg;
		private var _fullScreenBtn:CustomMcBtn;
		/**暂停按钮*/
		private var _fullPauseBtn:ScreenPauseBtn;
		
		private var _callFunc:Function;
		
		
		private var _w:int;
		private var _h:int;
		
		private var PlayProgressBgX:int=0;
		private var PlayProgressBgY:int=342;
		
		private const videoW:int=550;
		private const videoH:int=350;
		private const PlayMoveBtnX:int=0;
		private const PlayMoveBtnY:int=340;
		
		private var _playTimeText:TextField;
		private var _format:TextFormat;
		
		private const LeftDistance:int=10;
		private const RightDistance:int=10;
		
		private const PlayBtnY:int=360;
		private const VolumeMcX:int=430;
		private const VolumeMcY:int=360;
		
		private const SoundControllerMcY:int=355;
		/**声音拖动按钮初始位置*/
		private var _volumeBtnInitX:int;
		private var _volumeBtnX:int;
		private var _videoType:int=1;//1可以为normal,2为独立类型independence(独立类型就是单独弹出的)
		/**本地路径*/
		private var _localUrl:String="";
		/**网络路径*/
		private var _urlPath:String="";
		/**当前路径*/
		private var _curPath:String="";
		//全屏数据
		private var _fullData:FullScrenVideoData=new FullScrenVideoData;
		private var _curVolumeValue:Number;
		/**是否禁止声音*/
		private var _isVolumeStatic:Boolean=false;
		/**出错提醒返回函数*/
		private var _wrongTipFunc:Function;
		public var normalPlay:Function;
		private var _isFullScreen:Boolean=false;
		private var _client:Object;
		private const WrongTip:String="本地不存在该资源或是网络数据异常,无法播放视频";
		/**
		 * @param url
		 * */
		public function MyVideo(localUrl:String="",callFunc:Function=null,urlPath:String="",wrongTipFunc:Function=null)
		{
			var volumeMoveDistance:int;
			_urlPath=urlPath;
			_localUrl=localUrl;
			_curPath=_localUrl;
			_callFunc=callFunc;
			_wrongTipFunc=wrongTipFunc;
			
			this.graphics.beginFill(0x000000);
			this.graphics.drawRect(0,0,550,380);
			this.graphics.endFill();
			
			connect(_curPath);
		}
		
		public function set callFunc(func:Function):void
		{
			_callFunc=func;
		}
		
		
		private function chooseVolumeHandler(event:MouseEvent):void
		{
			var curFrame:int;
			//关闭声音
			if(_soundControllerMc.currentFrame==1)
			{
				curFrame=2;
				mySoundTransform.volume = 0;
				_volumeBtn.x=VolumeMcX;
				_curVolumeValue=mySoundTransform.volume;
				_volumeBtnX=_volumeBtn.x;
				_isVolumeStatic=true;
			}
			//打开声音
			else
			{
				curFrame=1;
				_curVolumeValue=1;
				mySoundTransform.volume=_curVolumeValue;
				_volumeBtn.x=_volumeBtnInitX;
				_isVolumeStatic=false;
			}
			_netStream.soundTransform = mySoundTransform;
			_soundControllerMc.gotoAndStop(curFrame);
		}
		
		private function addStageHandler(event:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE,addStageHandler);
		}
		
		public function set videoType(isType:int):void
		{
			_videoType=isType;
		}
		
		public function fullScreen(isFull:Boolean):void
		{
			_isFullScreen=isFull;
			
			if(_fullScreenBtn && !_isFullScreen)
			{
				this.removeChild(_fullScreenBtn);
				_fullScreenBtn.removeEventListener(MouseEvent.MOUSE_DOWN,fullScreenHandler);
			}
		}
		
		/**是否全屏*/
		private function fullScreenHandler(event:MouseEvent):void
		{
			//当前播放位置
			var curPlayBtnX:int=_playMoveBtn.x;
			var curPlayPos:Number=(_playMoveBtn.x)/videoW*_duration;
			trace(_videoType);
			if(_videoType==1)
			{
				_fullData.videoType=_videoType;
				_fullData.url=_localUrl;
				_fullData.w=_w;
				_fullData.h=_h;
				_fullData.curPlayMoveBtnX=curPlayBtnX;
				_fullData.curPlayPos=curPlayPos;
				_fullData.isPause=isPause;
				_fullData.curVolumeBtnX=_volumeBtn.x;
				_fullData.volumeValue=mySoundTransform.volume;
				_fullData.isVolumeStatic=_isVolumeStatic;
				_fullData.video=this;
				
				event.stopImmediatePropagation();
				_isFullScreen=!_isFullScreen;
				_callFunc(_fullData);
				_videoType=2;
			}
			else if(_videoType==2)
			{
				normalPlay();
				_videoType=1;
			}
			else
			{
			}
		}
		
		private function connect(url:String):void
		{
			_client=new Object();
			_client.onMetaData = onMetaData;
			_netConnection = new NetConnection  ;
			_netConnection.connect(null);
			_netStream = new NetStream(_netConnection);
			_netStream.play(url);
			_video = new Video(videoW,videoH);
			_video.attachNetStream(_netStream);
			addChild(_video);
			_netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,asyncErrorEvent);
			_netStream.client = _client;
			_netStream.addEventListener(NetStatusEvent.NET_STATUS, statusHandler);
			
			initOthers();
			pauseVideo();
		}
		
		private function initOthers():void
		{
			var volumeMoveDistance:int;
			
			_playBtn=new CustomMcBtn(new PlayBtn);
			_pauseBtn=new CustomMcBtn(new PauseBtn);
			
			_volumeBtn=new PlayMovBtn;
			_volumeMc=new VolumeMc;
			_playMoveBtn=new PlayMovBtn;
			_playMc=new PlayMc;
			_playBarBg=new PlayBarBg;
			_soundControllerMc=new SoundControllerMc;
			_soundControllerMc.gotoAndStop(1);
			_fullScreenBtn=new CustomMcBtn(new FullScreenBtn);
			
			_playBtn.x=LeftDistance;
			_playBtn.y=PlayBtnY;
			
			_pauseBtn.x=_playBtn.x;
			_pauseBtn.y=PlayBtnY;
			
			_fullPauseBtn=new ScreenPauseBtn;
			_fullPauseBtn.x=2;
			_fullPauseBtn.y=videoH-2-_fullPauseBtn.height;
			
			_playMoveBtn.x=PlayMoveBtnX;
			_playMoveBtn.y=PlayMoveBtnY;
			
			_volumeMc.x=VolumeMcX;
			_volumeMc.y=VolumeMcY+3;
			
			_soundControllerMc.x=405;
			_soundControllerMc.y=360;
			
			_volumeBtnInitX=_volumeMc.x+_volumeMc.width-_volumeBtn.width;
			_volumeBtn.x=_volumeBtnInitX;
			_volumeBtn.y=VolumeMcY;
			
			_playBarBg.x=PlayProgressBgX;
			_playBarBg.y=PlayProgressBgY;
			_playMc.x=PlayProgressBgX;
			_playMc.y=PlayProgressBgY;
			
			_format=new TextFormat;
			_format.size=12;
			_format.color=0xffffff;
			_playTimeText=new TextField;
			_playTimeText.width=80;
			_playTimeText.height=20;
			_playTimeText.defaultTextFormat=_format;
			
			_playTimeText.x=_playBtn.x+_playBtn.width+LeftDistance;
			_playTimeText.y=_playBtn.y+3;
			trace("_playTimeText.x,_playTimeText.y:",_playTimeText.x,_playTimeText.y);
			_fullScreenBtn.x=this.width-RightDistance-_fullScreenBtn.width;
			_fullScreenBtn.y=_playBtn.y;
			
			this.addChild(_playBtn);
			this.addChild(_pauseBtn);
			this.addChild(_volumeMc);
			this.addChild(_volumeBtn);
			
			this.addChild(_playBarBg);
			this.addChild(_playMc);
			this.addChild(_playMoveBtn);
			
			this.addChild(_fullScreenBtn);
			this.addChild(_soundControllerMc);
			
			this.addChild(_playTimeText);
			
			volumeMoveDistance=_volumeMc.width-_volumeBtn.width;
			volume_Rectangle=new Rectangle(VolumeMcX,VolumeMcY,volumeMoveDistance,0);
			play_Rectangle=new Rectangle(0,PlayMoveBtnY,videoW,0);
			
			_playBtn.addEventListener(MouseEvent.MOUSE_DOWN,playHandler);
			_pauseBtn.addEventListener(MouseEvent.MOUSE_DOWN,pauseHandler);
			_playMoveBtn.addEventListener(MouseEvent.MOUSE_DOWN,playDown_click);
			_playMoveBtn.addEventListener(MouseEvent.MOUSE_UP,playUp_click);
			
			_volumeBtn.addEventListener(MouseEvent.MOUSE_DOWN,volumeDown_click);
			_volumeBtn.addEventListener(MouseEvent.MOUSE_UP,volumeUp_click);
			_fullScreenBtn.addEventListener(MouseEvent.MOUSE_DOWN,fullScreenHandler);
			
			this.addEventListener(Event.ADDED_TO_STAGE,addStageHandler);
			
			_soundControllerMc.addEventListener(MouseEvent.MOUSE_DOWN,chooseVolumeHandler);
			
			_w=this.width;
			_h=this.height;
		}
		
		public function isPlay(value:Boolean):void
		{
			if(value)
			{
				playHandler(null);
			}
			else
			{
				pauseHandler(null);
			}
		}
		
		
		private function statusHandler(event:NetStatusEvent):void
		{
			_status=event.info.code;
			switch (event.info.code) {
				case "NetConnection.Connect.Success":
					break;
				case "NetStream.Play.StreamNotFound":
					trace("Stream not found: " + _curPath);
					if(_curPath==_localUrl)
					{
						trace("本地播放路径异常，开始选择网络路径播放");
						_curPath=_urlPath;
						reConnect(_curPath);
					}
					else if(_curPath==_urlPath)
					{
						trace("网络路径异常,无法播放视频");
						_wrongTipFunc(WrongTip);
					}
					break;
			}
		}
		
		private function reConnect(url:String):void
		{
			_netStream.close();
			_netStream.removeEventListener(AsyncErrorEvent.ASYNC_ERROR,asyncErrorEvent);
			_netStream.removeEventListener(NetStatusEvent.NET_STATUS, statusHandler);
			
			_netStream = new NetStream(_netConnection);
			_netStream.play(url);
			_video.attachNetStream(_netStream);
			_netStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR,asyncErrorEvent);
			_netStream.client = _client;
			_netStream.addEventListener(NetStatusEvent.NET_STATUS, statusHandler);
		}
		
		private function onMetaData(data:Object):void
		{
			_duration = data.duration;
		}
		private function playDown_click(event:MouseEvent):void
		{
			event.stopPropagation();
			p = false;
			_playMoveBtn.startDrag(false,play_Rectangle);
			removeEventListener(Event.ENTER_FRAME,ns_status);
		}
		private function playUp_click(event:MouseEvent):void
		{
			event.stopPropagation();
			_playMoveBtn.stopDrag();
			_netStream.seek((_playMoveBtn.x)/videoW*_duration);
			this.playVideo();
		}
		private function playUp_clickr(event:MouseEvent):void
		{
			if(!p)
			{
				_playMoveBtn.stopDrag();
				_netStream.seek((_playMoveBtn.x-40)/videoW*_duration);
				addEventListener(Event.ENTER_FRAME,ns_status);
				p = true;
			}
		}
		private function volumeDown_click(event:MouseEvent):void
		{
			event.stopPropagation();
			_volumeBtn.startDrag(false,volume_Rectangle);
		}
		private function volumeUp_click(event:MouseEvent):void
		{
			event.stopPropagation();
			_volumeBtn.stopDrag();
			mySoundTransform.volume = (_volumeBtn.x-449)/67;
			
			_isVolumeStatic=false;
			_netStream.soundTransform = mySoundTransform;
			_soundControllerMc.gotoAndStop(1);
		}
		private function ns_status(event:Event):void
		{
			var curTimer:String;
			var totalTimer:String;
			_playMc.scaleX = _netStream.time / _duration;
			_playBarBg.scaleX = _netStream.bytesLoaded / _netStream.bytesTotal;
			_playMoveBtn.x = _netStream.time / _duration * (videoW-_playMoveBtn.width);
			curTimer=transStandTime(Math.round(_netStream.time / 60)) + ":" + transStandTime(Math.round(_netStream.time % 60))+"/";
			totalTimer=transStandTime(Math.round(_duration / 60)) + ":" + transStandTime(Math.round(_duration % 60));
			_playTimeText.text=curTimer+totalTimer;
			if (_status == "NetStream.Play.Stop")
			{
				trace("again");
				_netStream.pause();
				_netStream.seek(0);
				_playMoveBtn.x = 0;
				_playMc.scaleX = 0;
				isPause = true;
				removeEventListener(Event.ENTER_FRAME,ns_status);
				changeState(false);
			}
		}
		
		/**转化为标准时间*/
		private function transStandTime(timer:Number):String
		{
			var msg:String=String(timer);
			if(msg.length==1)
			{
				msg="0"+msg;
			}
			return msg;
		}
		
		private function pauseHandler(event:MouseEvent):void
		{
			trace("pause");
			if(event)
			{
				event.stopImmediatePropagation();
			}
			pauseVideo();
		}
		
		private function pauseVideo():void
		{
			_netStream.pause();
			isPause = true;
			changeState(false);
			removeEventListener(Event.ENTER_FRAME,ns_status);
		}
		
		private function playHandler(event:MouseEvent):void
		{
			if(event)
			{
				event.stopImmediatePropagation();
			}
			
			playVideo();
		}
		
		private function playVideo():void
		{
			_netStream.resume();
			isPause = false;
			changeState(true);
			addEventListener(Event.ENTER_FRAME,ns_status);
		}
		
		private function changeState(isPause:Boolean=true):void
		{
			if(_playBtn)
			{
				_playBtn.visible=!isPause;
				_playBtn.mouseEnabled=!isPause;
				_playBtn.mouseChildren=!isPause;
			}
			
			if(_pauseBtn)
			{
				_pauseBtn.visible=isPause;
				_pauseBtn.mouseEnabled=isPause;
				_pauseBtn.mouseChildren=isPause;
			}
		}
		
		private function play_click(event:MouseEvent):void
		{
			if (!IsHiter)
			{
				_netStream.pause();
				IsHiter = true;
			}
			else
			{
				_netStream.resume();
				IsHiter = false;
			}
		}
		private function asyncErrorEvent(event:AsyncErrorEvent):void
		{
			trace("OK!");
		}
		
		/**清空，释放内存*/
		public function dispose():void
		{
			if(this.hasEventListener(Event.ENTER_FRAME))
			{
				removeEventListener(Event.ENTER_FRAME,ns_status);
			}
			
			_playBtn.removeEventListener(MouseEvent.MOUSE_DOWN,playHandler);
			_pauseBtn.removeEventListener(MouseEvent.MOUSE_DOWN,pauseHandler);
			_playMoveBtn.removeEventListener(MouseEvent.MOUSE_DOWN,playDown_click);
			_playMoveBtn.removeEventListener(MouseEvent.MOUSE_UP,playUp_click);
			
			_volumeBtn.removeEventListener(MouseEvent.MOUSE_DOWN,volumeDown_click);
			_volumeBtn.removeEventListener(MouseEvent.MOUSE_UP,volumeUp_click);
			_fullScreenBtn.removeEventListener(MouseEvent.MOUSE_DOWN,fullScreenHandler);
			_soundControllerMc.removeEventListener(MouseEvent.MOUSE_DOWN,chooseVolumeHandler);
			
			
			this.removeChild(_playBtn);
			this.removeChild(_pauseBtn);
			this.removeChild(_volumeMc);
			this.removeChild(_volumeBtn);
			
			this.removeChild(_playBarBg);
			this.removeChild(_playMc);
			this.removeChild(_playMoveBtn);
			
			this.removeChild(_fullScreenBtn);
			this.removeChild(_soundControllerMc);
			
			this.removeChild(_playTimeText);
			
			this.removeChild(_video);
			_netStream.close();
			_netConnection.close();
			
			_netStream=null;
			_netConnection=null;
			
			_playBtn=null;
			_pauseBtn=null;
			_volumeMc=null;
			_volumeBtn=null;
			_playBarBg=null;
			_playMc=null;
			_playMoveBtn=null;
			_fullScreenBtn=null;
			_soundControllerMc=null;
			_playTimeText=null;
		}
	}
}