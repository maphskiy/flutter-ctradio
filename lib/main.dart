import 'dart:async';
import 'package:ctradio/player/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_radio_player/flutter_radio_player.dart';
import 'package:shimmer/shimmer.dart';

typedef void OnError(Exception exception);

const kUrl = "https://radio.criminaltribe.com:8443/radio_stream";
const secondsToBuffer = 10;
const trackInfoUpdateTimeout = 15;
const debug = true;

void main() {
  // AudioPlayer.logEnabled = true;
  runApp(new MaterialApp(
      title: "Criminal Tribe Radio", home: new Scaffold(body: new RadioApp())));
}

class RadioApp extends StatefulWidget {
  @override
  _RadioAppState createState() => new _RadioAppState();
}

class _RadioAppState extends State<RadioApp> {
  PlayerState playerState = PlayerState.playing;
  // Player player = new Player();
  FlutterRadioPlayer player = new FlutterRadioPlayer();
  String track = "";

  get isPlaying => playerState == PlayerState.playing;
  get isLoading => playerState == PlayerState.loading;

  @override
  void initState() {
    super.initState();
    player.isPlayingStream.listen((event) {
      print(event);
      switch (event) {
        case FlutterRadioPlayer.flutter_radio_stopped:
          setState(() => {playerState = PlayerState.paused});
          break;
        case FlutterRadioPlayer.flutter_radio_loading:
          setState(() => {playerState = PlayerState.loading});
          break;
        case FlutterRadioPlayer.flutter_radio_playing:
          setState(() => {playerState = PlayerState.playing});
          break;
        case FlutterRadioPlayer.flutter_radio_paused:
          setState(() => {playerState = PlayerState.paused});
          break;
      }
    });
    player.metaDataStream.listen((event) {
      setState(() {
        track = event;
      });
    });
    player.init("Criminal Tribe App", "Radio", kUrl, "false");
  }

  @override
  void dispose() {
    print('dispose');
    player.stop();
    super.dispose();
  }

  Future<bool> _onWillPop() {
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Giving up?'),
        content: new Text('Do you want to exit'),
        actions: <Widget>[
          new FlatButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: new Text('No'),
          ),
          new FlatButton(
            onPressed: () {
              player.stop();
              return Navigator.of(context).pop(true);
            },
            child: new Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        child:
            new OrientationBuilder(builder: (orientationContext, orientation) {
          return new Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: orientation == Orientation.portrait
                          ? BoxFit.fitHeight
                          : BoxFit.fitWidth,
                      image: AssetImage('assets/bg_full.png'))),
              child: new LayoutBuilder(
                  builder: (context, constraints) => Column(
                        children: <Widget>[
                          SizedBox(
                            height: (constraints.maxHeight -
                                    constraints.minHeight) *
                                0.3,
                            width: constraints.maxWidth,
                            child: new Container(
                                alignment: Alignment.topLeft,
                                color: Colors.transparent,
                                child: _buildHeader(orientation)),
                          ),
                          SizedBox(
                            height: (constraints.maxHeight -
                                    constraints.minHeight) *
                                0.4,
                            width: constraints.maxWidth,
                            child: new Container(
                                color: Colors.transparent,
                                child: _buildPlayer()),
                          ),
                          SizedBox(
                            height: (constraints.maxHeight -
                                    constraints.minHeight) *
                                0.3,
                            child: _buildTrackInfo(),
                          ),
                        ],
                      )));
        }),
        onWillPop: _onWillPop);
  }

  Widget _buildPlayer() => new Container(
      decoration: BoxDecoration(
          image: DecorationImage(
              fit: BoxFit.fitHeight, image: AssetImage('assets/btn_bg.png'))),
      child: new LayoutBuilder(
          builder: (context, contstraints) => Center(
                child: new ConstrainedBox(
                  constraints: new BoxConstraints.tight(
                      Size.fromRadius(contstraints.maxHeight * 0.225)),
                  child: FloatingActionButton(
                    backgroundColor: Colors.transparent,
                    child: isLoading
                        ? SizedBox(
                            child: CircularProgressIndicator(
                              strokeWidth: 4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.fromRGBO(255, 255, 255, 0.8)),
                            ),
                            height: contstraints.maxHeight,
                            width: contstraints.maxHeight,
                          )
                        : (isPlaying
                            ? Image.asset('assets/stop_btn.png')
                            : Image.asset('assets/play_btn.png')),
                    onPressed: () => isLoading ? null : player.playOrPause(),
                  ),
                ),
              )));
  Widget _buildHeader(Orientation orientation) => new Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                alignment: Alignment.topLeft,
                fit: orientation == Orientation.portrait
                    ? BoxFit.fitWidth
                    : BoxFit.fitHeight,
                image: AssetImage('assets/header.png'))),
      );

  Widget _buildTrackInfo() => new Container(
      alignment: Alignment.center,
      padding: EdgeInsets.all(20),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            isPlaying
                ? Shimmer.fromColors(
                    baseColor: Color.fromRGBO(255, 255, 255, 0.7),
                    highlightColor: Colors.white,
                    child: Text(
                      track,
                      textAlign: TextAlign.center,
                      textScaleFactor: 1.8,
                    ),
                  )
                : Text(
                    track,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 0.7),
                    ),
                    textScaleFactor: 1.8,
                  ),
          ]));
}
