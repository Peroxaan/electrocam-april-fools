import 'dart:async';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:electrocam/take_picture_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(ElectrocamApp());
}

class ElectrocamApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electrocam',
      theme: ThemeData(
          fontFamily: 'Eudoxus Sans',
          brightness: Brightness.dark,
          primarySwatch: Colors.pink,
          textTheme: TextTheme(
              headline1: TextStyle(
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold))),
      home: Camera(),
    );
  }
}

List<CameraDescription>? cameras;

class Camera extends StatefulWidget {
  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? controller;
  PageController pageController = PageController();
  double opacity = 1.0;
  Timer? debounce;
  double wide = 1.0;
  Duration takePhotoDuration = Duration(milliseconds: 50);
  double takePhotoOpacity = 0.0;
  Timer? takePhotoDebounce;
  Timer? takePhotoDebounce2;

  void takePhoto() async {
    setState(() => takePhotoOpacity = 1);

    if (takePhotoDebounce?.isActive ?? false) takePhotoDebounce?.cancel();
    takePhotoDebounce = Timer(const Duration(milliseconds: 50), () {
      takePhotoDuration = Duration(milliseconds: 300);
      setState(() => takePhotoOpacity = 0.0);

      if (takePhotoDebounce2?.isActive ?? false) takePhotoDebounce2?.cancel();
      takePhotoDebounce2 = Timer(const Duration(milliseconds: 300), () {
        takePhotoDuration = Duration(milliseconds: 50);
      });
    });
  }

  void setDebounce() {
    if (debounce?.isActive ?? false) debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => opacity = 0);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = CameraController(cameras![0], ResolutionPreset.max);
    controller!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });

    setDebounce();

    pageController.addListener(() {
      setState(() {
        opacity = 1.0;
        wide = pageController.page! + 1;
      });
      setDebounce();
    });
  }

  @override
  void didChangeAppLifecycleState(dynamic state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller!.description);
      }
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }
    controller = CameraController(
      cameras![0],
      ResolutionPreset.veryHigh,
    );
    controller!.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set transparent bars
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.transparent,
        statusBarColor: Colors.transparent));
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: CameraPreview(controller!),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5)),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
          ),
          controller!.value.isInitialized
              ? SafeArea(
                  child: Align(
                  alignment: Alignment.topCenter,
                  child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: SizedBox(
                          height: (16 * MediaQuery.of(context).size.width) / 9,
                          width: MediaQuery.of(context).size.width * wide,
                          child: BackdropFilter(
                              filter: ui.ImageFilter.blur(
                                  sigmaX: 15.0, sigmaY: 15.0),
                              child: CameraPreview(controller!)),
                        ),
                      )),
                ))
              : Container(),
          AnimatedOpacity(
            opacity: opacity > 0.5 ? 0.5 : opacity,
            duration: Duration(milliseconds: 150),
            child: Container(
              decoration: BoxDecoration(color: Colors.black),
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
            ),
          ),
          NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (OverscrollIndicatorNotification overScroll) {
                overScroll.disallowIndicator();
                return false;
              },
              child: PageView(
                controller: pageController,
                children: [
                  AnimatedOpacity(
                    opacity: opacity,
                    duration: Duration(milliseconds: 500),
                    child: Center(
                        child: Text(
                      'Photo Mode',
                      style: Theme.of(context).textTheme.headline1,
                    )),
                  ),
                  AnimatedOpacity(
                    opacity: opacity,
                    duration: Duration(milliseconds: 500),
                    child: Center(
                        child: Text(
                      'Wide Mode',
                      style: Theme.of(context).textTheme.headline1,
                    )),
                  ),
                ],
              )),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: TakePictureButton(onTap: takePhoto)),
          )
        ],
      ),
    );
  }
}
