import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:mypt/models/pull_up_analysis.dart';
import 'package:mypt/models/push_up_analysis.dart';
import 'package:mypt/models/squat_analysis.dart';
import 'package:mypt/models/workout_analysis.dart';
import 'package:provider/provider.dart';

import 'camera_view.dart';
import '../painter/pose_painter.dart';
import '../utils.dart';

class PoseDetectorView extends StatefulWidget {
  PoseDetectorView({Key? key, required this.workoutName}) : super(key: key);
  String workoutName;

  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> {
  PoseDetector poseDetector = GoogleMlKit.vision.poseDetector();
  bool isBusy = false;
  CustomPaint? customPaint;
  late WorkoutAnalysis _workoutAnalysis;
  bool detecting = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.workoutName == 'pushup') {
      _workoutAnalysis = PushUpAnalysis();
    } else if (widget.workoutName == 'squat') {
      _workoutAnalysis = SquatAnalysis();
    } else {
      _workoutAnalysis = PullUpAnalysis();
    }
  }

  @override
  void dispose() async {
    super.dispose();
    await poseDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      //카메라 뷰를 실행(custom paint를 사용하고 onimage function으로
      // processImage 사용
      title: widget.workoutName,
      customPaint: customPaint,
      onImage: (inputImage) {
        processImage(inputImage);
      },
      workoutAnalysis: _workoutAnalysis,
      floatingActionButton : floatingActionButton,
      isDetecting: isDetecting
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    final poses = await poseDetector.processImage(inputImage);
    print('Found ${poses.length} poses');
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      try {
        if (detecting) {
          if (poses.isNotEmpty) {
            _workoutAnalysis.detect(poses[0]);
            print("현재 푸쉬업 개수 :");
            print(_workoutAnalysis.count);
          }
        }
      } catch (e) {
        print("processImage에서 provider 작동안함 : $e");
      }
      final painter = PosePainter(poses, inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      customPaint = CustomPaint(painter: painter);
    } else {
      customPaint = null;
    }
    isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Widget? floatingActionButton() {
    return Container(
        height: 70.0,
        width: 70.0,
        child: FloatingActionButton(
          child: detecting
              ? const Icon(Icons.stop_circle_rounded, size: 40)
              : const Icon(Icons.play_arrow_rounded, size: 40),
          onPressed: () => {
            detecting
                ? stopDetecting()
                : startDetecting()
          },
        ));
  }

  void startDetecting(){
    setState(){
      detecting = true;
    }
  }

  void stopDetecting(){
    setState(){
      detecting = false;
    }
  }

  bool isDetecting(){
    return detecting;
  }
}
