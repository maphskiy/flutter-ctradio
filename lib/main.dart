import 'dart:async';
import 'package:ctradio/player/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_radio_player/flutter_radio_player.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';

typedef void OnError(Exception exception);

const trackTextScale = 1.8;
const trackTextColor = Color.fromRGBO(255, 255, 255, 0.7);

void main() {
  runApp(new MaterialApp(
      title: "Criminal Tribe Radio", home: new Scaffold(body: new RadioApp())));
}

class RadioApp extends StatefulWidget {
  @override
  _RadioAppState createState() => new _RadioAppState();
}

class _RadioAppState extends State<RadioApp>
    with SingleTickerProviderStateMixin {
  PlayerState playerState = PlayerState.paused;
  Player player = new Player();
  String track = "";
  Animation _heartAnimation;
  AnimationController _heartAnimationController;

  get isPlaying => playerState == PlayerState.playing;
  get isLoading => playerState == PlayerState.loading;

  @override
  void initState() {
    super.initState();
    player.playerStateStream.listen((event) {
      print(event);
      switch (event) {
        case FlutterRadioPlayer.flutter_radio_stopped:
          setState(() => {playerState = PlayerState.stoped});
          _heartAnimationController.reset();
          break;
        case FlutterRadioPlayer.flutter_radio_loading:
          setState(() => {playerState = PlayerState.loading});
          _heartAnimationController.reset();
          break;
        case FlutterRadioPlayer.flutter_radio_playing:
          setState(() => {playerState = PlayerState.playing});
          _heartAnimationController.forward();
          break;
        case FlutterRadioPlayer.flutter_radio_paused:
          setState(() => {playerState = PlayerState.paused});
          _heartAnimationController.reset();
          break;
      }
    });
    player.trackStream.listen((event) {
      setState(() {
        track = event;
      });
    });
    player.playerInit();

    var baseSpeed = 570;
    _heartAnimationController = AnimationController(
        vsync: this, duration: Duration(milliseconds: baseSpeed));
    _heartAnimation = Tween(begin: 0, end: 0.01).animate(CurvedAnimation(
        curve: Curves.bounceOut, parent: _heartAnimationController));

    _heartAnimationController.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _heartAnimationController.repeat();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    player.stop();
    _heartAnimationController?.dispose();
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
    double statusBarHeight = MediaQuery.of(context).padding.top;
    return new WillPopScope(
        child:
            new OrientationBuilder(builder: (orientationContext, orientation) {
          return new Container(
              padding: EdgeInsets.only(top: statusBarHeight),
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
                            child: new Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.all(20),
                                child: _buildTrackInfo()),
                          ),
                        ],
                      )));
        }),
        onWillPop: _onWillPop);
  }

  Widget _buildPlayer() => AnimatedBuilder(
        animation: _heartAnimationController,
        builder: (context, child) {
          return Container(
              margin: EdgeInsets.all(
                  MediaQuery.of(context).size.height * _heartAnimation.value),
              decoration: BoxDecoration(
                  image: DecorationImage(
                      fit: BoxFit.fitHeight,
                      image: AssetImage('assets/btn_bg.png'))),
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
                            onPressed: () => isLoading
                                ? null
                                : player.playOrPause(playerState),
                          ),
                        ),
                      )));
        },
      );
  Widget _buildHeader(Orientation orientation) => new Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                alignment: Alignment.topLeft,
                fit: orientation == Orientation.portrait
                    ? BoxFit.fitWidth
                    : BoxFit.fitHeight,
                image: AssetImage('assets/header.png'))),
      );

  Widget _buildTrackInfo() => new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Clipboard.setData(new ClipboardData(text: track)).then((_) {
                  Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("Track name copied to clipboard")));
                });
              },
              child: isPlaying
                  ? Shimmer.fromColors(
                      baseColor: trackTextColor,
                      highlightColor: Colors.white,
                      child: Text(
                        track,
                        textAlign: TextAlign.center,
                        textScaleFactor: trackTextScale,
                      ),
                    )
                  : Text(
                      track,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: trackTextColor,
                      ),
                      textScaleFactor: trackTextScale,
                    ),
            )
          ]);
}
