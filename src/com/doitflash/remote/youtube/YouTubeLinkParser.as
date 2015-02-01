package com.doitflash.remote.youtube
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.EventDispatcher;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequestMethod;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import air.net.URLMonitor;
	import flash.events.StatusEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.ProgressEvent;
	
	/**
	 * Using this class will help you parse standard YouTube urls to find out different availble video formats and qualities.
	 * if you want to simply support YouTube play on your apps, I suggest you to use the official YouTube API availble at:
	 * <a href="https://developers.google.com/youtube/">https://developers.google.com/youtube/</a>
	 * 
	 * <p>in rare cases like needing to play videos over texture when building Augmented Reality apps, you would need to
	 * download the video file first and that's when this class will be helpful</p>
	 * 
	 * <p>This library is mainly based on the following PHP lib <a href="https://github.com/jeckman/YouTube-Downloader">
	 * https://github.com/jeckman/YouTube-Downloader</a></p>
	 *
	 * <p><b>NOTICE: </b>I cannot give any gurantee that this class would always work! because YouTube changes all the time
	 * and the way to parse the information may change from time to time! This is an open source project, feel free to change it
	 * any way you like to make it work again! :D All I can say is that it is working as today that I have built it! Nov 10, 2014</p>
	 * 
	 * @example use the lib like this: 
	 * <listing version="3.0">
	 *	import com.doitflash.remote.youtube.YouTubeLinkParser;
	 *	import com.doitflash.remote.youtube.YouTubeLinkParserEvent;
	 *	import com.doitflash.remote.youtube.VideoType;
	 *	import com.doitflash.remote.youtube.VideoQuality;
	 *	
	 *	var _ytParser:YouTubeLinkParser = new YouTubeLinkParser();
	 *	_ytParser.addEventListener(YouTubeLinkParserEvent.COMPLETE, onComplete);
	 *	_ytParser.addEventListener(YouTubeLinkParserEvent.ERROR, onError);
	 *	_ytParser.parse("https://www.youtube.com/watch?v=QowwaefoCec");
	 *	
	 *	function onError(e:YouTubeLinkParserEvent):void
	 *	{
	 *		// removing listeners just for clean cosing reasons!
	 *		_ytParser.removeEventListener(YouTubeLinkParserEvent.COMPLETE, onComplete);
	 *		_ytParser.removeEventListener(YouTubeLinkParserEvent.ERROR, onError);
	 * 		
	 *		trace("Error: " + e.param.msg);
	 *	}
	 *	
	 *	function onComplete(e:YouTubeLinkParserEvent):void
	 *	{
	 *		// removing listeners just for clean coding reasons!
	 *		_ytParser.removeEventListener(YouTubeLinkParserEvent.COMPLETE, onComplete);
	 *		_ytParser.removeEventListener(YouTubeLinkParserEvent.ERROR, onError);
	 *		
	 *		trace("youTube parse completed...");
	 *		trace("video thumb: " + _ytParser.thumb);
	 *		trace("video title: " + _ytParser.title);
	 *		trace("possible found videos: " + _ytParser.videoFormats.length);
	 *		
	 *		trace("you can only access youtube public videos... no age restriction for example!");
	 *		trace("some video formats may be null so you should check their availablily...");
	 *		trace("to make your job easier, I built another method called getHeaders() which will load video headers for you! 
	 *		you can know the video size using these header information :) ")
	 *		
	 *		// let's find the VideoType.VIDEO_MP4 video format in VideoQuality.MEDIUM for this video
	 *		// NOTICE: you should find your own way of selecting a video format! as different videos may not have all formats or qualities available!
	 *		
	 *		var currVideoData:URLVariables;
	 *		var chosenVideo:String;
	 *		for (var i:int = 0; i &lt; _ytParser.videoFormats.length; i++) 
	 *		{
	 *			currVideoData = _ytParser.videoFormats[i];
	 *			if (currVideoData.type == VideoType.VIDEO_MP4 &amp;&amp; currVideoData.quality == VideoQuality.MEDIUM)
	 *			{
	 *				chosenVideo = currVideoData.url;
	 *				break;
	 *			}
	 *		}
	 *		
	 *		_ytParser.addEventListener(YouTubeLinkParserEvent.VIDEO_HEADER_RECEIVED, onHeadersReceived);
	 *		_ytParser.addEventListener(YouTubeLinkParserEvent.VIDEO_HEADER_ERROR, onHeadersError);
	 *		_ytParser.getHeaders(chosenVideo);
	 *	}
	 *	
	 *	function onHeadersError(e:YouTubeLinkParserEvent):void
	 *	{
	 *		_ytParser.removeEventListener(YouTubeLinkParserEvent.VIDEO_HEADER_RECEIVED, onHeadersReceived);
	 *		_ytParser.removeEventListener(YouTubeLinkParserEvent.VIDEO_HEADER_ERROR, onHeadersError);
	 *		
	 *		trace("Error: " + e.param.msg)
	 *	}
	 *	
	 *	function onHeadersReceived(event:YouTubeLinkParserEvent):void
	 *	{
	 *		_ytParser.removeEventListener(YouTubeLinkParserEvent.VIDEO_HEADER_RECEIVED, onHeadersReceived);
	 *		_ytParser.removeEventListener(YouTubeLinkParserEvent.VIDEO_HEADER_ERROR, onHeadersError);
	 *		
	 *		var lng:int = event.param.headers.length;
	 *		var i:int;
	 *		var currHeader:*;
	 *		
	 *		for (i = 0; i &lt; lng; i++ )
	 *		{
	 *			currHeader = event.param.headers[i];
	 *			trace(currHeader.name + " = " + currHeader.value);
	 *		}
	 *		
	 *		// ok, we are happy! now let's download this video, like any other file you would download:
	 *		download(event.param.url);
	 *	}
	 * </listing>
	 * 
	 * @author Hadi Tavakoli - 11/6/2014 6:14 PM
	 */
	public class YouTubeLinkParser extends EventDispatcher
	{
		private var _orginalLink:String;
		private var _videoId:String;
		private var _thumbLink:String;
		private var _videoTitleOrg:String;
		private var _videoTitle:String;
		private var _videoFormats:Array;
		
		public function YouTubeLinkParser():void
		{
			
		}
		
// -------------------------------------------------------------------------------------- functions

		private function onRawDataReceived(e:Event):void
		{
			var loader:URLLoader = e.target as URLLoader;
			
			// remove listeners for this request
			loader.removeEventListener(Event.COMPLETE, onRawDataReceived);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onFailure);
			
			var videoVars:URLVariables = loader.data;
			
			// variables that we need to work with:
			_thumbLink = videoVars.thumbnail_url;
			_videoTitleOrg = videoVars.title;
			_videoTitle = cleanTitle(videoVars.title);
			
			var formatsRaw:Array = String(videoVars.url_encoded_fmt_stream_map).split(",");
			var lng:int = formatsRaw.length;
			var i:int;
			var vars:URLVariables;
			var urlVars:URLVariables;
			_videoFormats = [];
			
			for (i = 0; i < lng; i++)
			{
				vars = new URLVariables(formatsRaw[i]);
				vars.type = String(vars.type).split(";")[0];
				urlVars = new URLVariables(decodeURI(vars.url));
				vars.expire = urlVars.expire;
				vars.ipbits = urlVars.ipbits;
				vars.ip = urlVars.ip;
				vars.url = vars.url + "&title=" + _videoTitle;
				delete(vars.fallback_host)
				
				_videoFormats.push(vars);
			}
			
			dispatchEvent(new YouTubeLinkParserEvent(YouTubeLinkParserEvent.COMPLETE, _videoFormats));
		}
		
		private function onFailure(e:IOErrorEvent):void
		{
			var loader:URLLoader = e.target as URLLoader;
			
			// remove listeners for this request
			loader.removeEventListener(Event.COMPLETE, onRawDataReceived);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onFailure);
			
			dispatchEvent(new YouTubeLinkParserEvent(YouTubeLinkParserEvent.ERROR, {msg:"could not connect to server!"} ));
		}
		
		private function cleanTitle($str:String):String
		{
			$str = $str.replace(" ", "-");
			
			var pattern:RegExp = /[^A-Za-z0-9\-]/g;
			$str = $str.replace(pattern, "");
			
			return $str;
		}
		
		private function extractYoutubeId($link:String):String
		{
			var id:String;
			
			var pattern:RegExp = /v=/i;
			if (!pattern.test($link)) return null;
			id = $link.substr($link.search(pattern) + 2, 11);
			if (id.indexOf("&") > -1) return null;
			
			return id;
		}
		
		

// -------------------------------------------------------------------------------------- Methods

		/**
		 * Pass in a standard youtube link to start parsing the link. watch out for the listeners to see the results.
		 * 
		 * @param	$youtubeUrl
		 */
		public function parse($youtubeUrl:String):void
		{
			_orginalLink = $youtubeUrl;
			_videoId = extractYoutubeId(_orginalLink);
			
			if (!_videoId)
			{
				dispatchEvent(new YouTubeLinkParserEvent(YouTubeLinkParserEvent.ERROR, {msg:"invalid link!"} ));
			}
			
			var vidInfo:String = 'http://www.youtube.com/get_video_info?&video_id=' + _videoId + '&asv=3&el=detailpage&hl=en_US';
			
			// setup the request method to connect to server
			var request:URLRequest = new URLRequest(vidInfo);
			request.userAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:8.0.1)";
			request.method = URLRequestMethod.POST;
			request.manageCookies = true;
			
			// add listeners and send out the information
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onRawDataReceived);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onFailure);
			loader.dataFormat = URLLoaderDataFormat.VARIABLES;
			loader.load(request);
		}
		
		/**
		 * Use this method to check if this video file is available for download or not.
		 * add the following listeners to manage it:
		 *
		 * <listing version="3.0">
		 * _ytParser.addEventListener(YouTubeLinkParserEvent.VIDEO_HEADER_RECEIVED, onHeadersReceived);
		 * _ytParser.addEventListener(YouTubeLinkParserEvent.VIDEO_HEADER_ERROR, onHeadersError);
		 * </listing>
		 * 
		 * if video is availble, you should be receiving the folwoing information (including the video size in bytes "Content-Length")
		 * <listing version="3.0">
		 * function onHeadersReceived(e:YouTubeLinkParserEvent):void
		 * {
		 * 		for (var i:int = 0; i &lt; e.param.headers.length; i++ )
		 * 		{
		 * 			trace(e.param.headers.name + " = " + e.param.headers.value);
		 * 		}
		 * }
		 * 
		 * 
		 *	Last-Modified = Fri, 17 Oct 2014 21:46:47 GMT
		 *	Content-Type = video/webm
		 *	Content-Disposition = attachment; filename="AR-AirNativeExtensionsupportingAndroidandiOS.webm"
		 *	Date = Thu, 06 Nov 2014 16:27:30 GMT
		 *	Expires = Thu, 06 Nov 2014 16:27:30 GMT
		 *	Cache-Control = private, max-age=21299
		 *	Accept-Ranges = bytes
		 *	Content-Length = 5458106
		 *	Connection = close
		 *	X-Content-Type-Options = nosniff
		 *	Server = gvs 1.0
		 * </listing>
		 * 
		 * @param	$url	video url retrived from this library
		 */
		public function getHeaders($url:String):void
		{
			var request:URLRequest = new URLRequest($url);
			request.userAgent = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:8.0.1)";
			request.method = URLRequestMethod.HEAD;
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, onHttp); 
			loader.addEventListener(IOErrorEvent.IO_ERROR, onFailure);
			loader.load(request);
			
			function onFailure(e:IOErrorEvent):void
			{
				dispatchEvent(new YouTubeLinkParserEvent(YouTubeLinkParserEvent.VIDEO_HEADER_ERROR, {msg:"connection problem or video is not available. try another video format!"} ));
			}
			
			function onHttp(event:HTTPStatusEvent):void
			{
				dispatchEvent(new YouTubeLinkParserEvent(YouTubeLinkParserEvent.VIDEO_HEADER_RECEIVED, { headers:event.responseHeaders, url:$url } ));
			}
		}

// -------------------------------------------------------------------------------------- properties

		public function get videoFormats():Array
		{
			return _videoFormats;
		}
		
		public function get thumb():String
		{
			return _thumbLink;
		}
		
		public function get title():String
		{
			return _videoTitleOrg;
		}

	}
}