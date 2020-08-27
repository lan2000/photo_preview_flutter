import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_preview/photo_preview_export.dart';
import 'package:photo_preview/src/photo_preview_page/singleton/photo_preview_value_singleton.dart';
import 'package:photo_preview/src/utils/photo_preview_tool_utils.dart';
import 'package:photo_preview/src/widget/custom_chewie/custom_chewie_widget.dart';
import 'package:photo_preview/src/widget/video_control/custom_video_control.dart';
import 'package:photo_preview/src/widget/video_control/photo_video_status_type.dart';
import 'package:video_player/video_player.dart';

///视频播放器
class PhotoPreviewVideoWidget extends StatefulWidget {

  ///视频详情
  final PhotoPreviewInfoVo videoInfo;

  ///当前位置
  final int currentPostion;

  const PhotoPreviewVideoWidget({Key key, this.videoInfo, this.currentPostion})
      : super(key: key);

  @override
  _PhotoPreviewVideoWidgetState createState() =>
      _PhotoPreviewVideoWidgetState();
}

class _PhotoPreviewVideoWidgetState extends State<PhotoPreviewVideoWidget>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  VideoPlayerController videoPlayerController;
  CustomChewieController chewieController;

  ///是否销毁
  bool isDisposed = false;

  ///记录状态类型
  PhotoVideoStatusType recordType;

  ///是否加载完成
  bool isLoadComplete = false;

//  ///是否加载完成controller
//  StreamController<bool> isLoadCompleteController = StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget?.videoInfo?.url == null || widget.videoInfo.url.isEmpty) {
      return;
    } else if (PhotoPreviewToolUtils.isNetUrl(widget?.videoInfo?.url)) {
      videoPlayerController =
          VideoPlayerController.network(widget?.videoInfo?.url);
    } else {
      videoPlayerController =
          VideoPlayerController.file(File(widget?.videoInfo?.url));
    }

    _initListener();
    _initData();
  }

  _initListener() {
    //监听初始化未完成时
    videoPlayerController?.addListener(() => _initVideoControllerListener());

    if (widget?.currentPostion != null && widget.currentPostion >= 0) {
      PhotoPreviewValueSingleton.getInstance()
          .pageIndexController
          ?.stream
          ?.listen((position) {
        if (position != widget?.currentPostion) {
          ///未记录
          if (recordType == null) {
            recordType = (videoPlayerController?.value?.isPlaying ?? true)
                ? PhotoVideoStatusType.playing
                : PhotoVideoStatusType.pause;
            videoPlayerController?.pause();
          }

        }else if(position == widget?.currentPostion){
          ///释放记录类型状态
          if(recordType != null){
            if(recordType == PhotoVideoStatusType.playing){
              videoPlayerController?.play();
            }else{
              videoPlayerController?.pause();
            }
            recordType = null;
          }
        }
      });
    }
  }

  _initVideoControllerListener(){
      ///初始化完成
    if(!isLoadComplete) {
      if ((videoPlayerController?.value?.initialized ?? false) && (videoPlayerController?.value?.position?.inMilliseconds ?? 0)> 200) {
        //完成标志
        isLoadComplete = true;
        if (recordType != null) {
          videoPlayerController?.pause();
        } else {
          videoPlayerController?.play();
        }
      }
    }
//    ///判断去除封面的原因
//    if(videoPlayerController?.value != null){
//      isLoadCompleteController?.add(true);
//    }
  }

  _initData() {
    chewieController = CustomChewieController(
        videoPlayerController: videoPlayerController,
        aspectRatio: null,
        autoPlay: true,
        looping: false,
        startAt: null,
//        placeholder: _toPlaceHolderWidget(),
        customControls: CustomControls(
          controller: videoPlayerController,
          chewieController: chewieController,
        ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _toMainWidget();
  }

  Widget _toMainWidget() {
    if (widget?.videoInfo?.url == null || widget.videoInfo.url.isEmpty) {
      return Container();
    }
    return ExtendsCustomWidget(
      child: Container(
          child: CustomChewie(
            vCoverUrl:widget?.videoInfo?.vCoverUrl,
        controller: chewieController,
      )),
    );
  }

//  Widget _toPlaceHolderWidget(){
//    return StreamBuilder<bool>(
//      initialData: false,
//      stream: isLoadCompleteController?.stream,
//      builder: (context, snapshot) {
//        return Offstage(
//          offstage: snapshot?.data == true,
//          child: Center(
//            child: Container(
//              width: 400,
//              height: 300,
//              color: Colors.green,
//            ),
//          ),
//        );
//      }
//    );
//  }

  @override
  void dispose() {
    isDisposed = true;
    videoPlayerController.dispose();
    chewieController.dispose();
//    isLoadCompleteController.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;
}
