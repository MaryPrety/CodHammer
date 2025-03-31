import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class BetPage extends StatefulWidget {
  const BetPage({super.key});

  @override
  _BetPageState createState() => _BetPageState();
}

class _BetPageState extends State<BetPage> {
  late VideoPlayerController _videoController;
  bool _isFullScreen = false;
  bool _isEnglish = false;

  // Dynamic percentage values
  double firstRobotPercentage = 80.0;
  double secondRobotPercentage = 20.0;
  double firstRobotCoefficient = 1.143;
  double secondRobotCoefficient = 2.333;
  String matchTime = "15:30";

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset('assets/videos/sample_video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(true);
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062B42),
      body: _isFullScreen ? _buildFullScreenVideo() : _buildMainContent(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFCDFBE4),
        onPressed: _toggleLanguage,
        child: Text(
          _isEnglish ? 'RU' : 'EN',
          style: const TextStyle(
            color: Color(0xFF062B42),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'CodHammer',
                  style: const TextStyle(
                    color: Color(0xFFCDFBE4),
                    fontSize: 30,
                    fontFamily: 'Tomorrow',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Roboport of Moscow\nBattle of the Russians',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFCDFBE4),
                    fontSize: 18,
                    fontFamily: 'Tomorrow',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Percentage and Coefficient Block
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCDFBE4), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipPath(
              clipper: OctagonalClipper(),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCDFBE4), width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${firstRobotPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFFCDFBE4),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${secondRobotPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFFCDFBE4),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress Bar
                    Stack(
                      children: [
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: const Color(0xFF0A3A5A),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: firstRobotPercentage / 100,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: const Color(0xFFCDFBE4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Coefficients
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCoefficient(firstRobotCoefficient),
                        _buildCoefficient(secondRobotCoefficient),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Video Player with Octagonal Frame
          GestureDetector(
            onTap: () {
              setState(() {
                _isFullScreen = true;
              });
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(205, 251, 228, 0.45),
                    offset: const Offset(-4, 4),
                    blurRadius: 45,
                  ),
                ],
              ),
              child: ClipPath(
                clipper: OctagonalClipper(),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: VideoPlayer(_videoController),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Footer Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  'On general matters',
                  style: const TextStyle(
                    color: Color(0xFFCDFBE4),
                    fontSize: 16,
                    fontFamily: 'Tomorrow',
                  ),
                ),
                Text(
                  'info@bitva-robotov.ru',
                  style: const TextStyle(
                    color: Color(0xFFCDFBE4),
                    fontSize: 16,
                    fontFamily: 'Tomorrow',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'On participation',
                  style: const TextStyle(
                    color: Color(0xFFCDFBE4),
                    fontSize: 16,
                    fontFamily: 'Tomorrow',
                  ),
                ),
                Text(
                  'team@bitva-robotov.ru',
                  style: const TextStyle(
                    color: Color(0xFFCDFBE4),
                    fontSize: 16,
                    fontFamily: 'Tomorrow',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenVideo() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFullScreen = false;
        });
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      },
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _videoController.value.aspectRatio,
              child: VideoPlayer(_videoController),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isFullScreen = false;
                });
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoefficient(double coefficient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFCDFBE4),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        coefficient.toStringAsFixed(3),
        style: const TextStyle(
          color: Color(0xFF062B42),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _toggleLanguage() {
    setState(() {
      _isEnglish = !_isEnglish;
    });
  }
}

class OctagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double cut = size.width / 6;
    path.moveTo(cut, 0);
    path.lineTo(size.width - cut, 0);
    path.lineTo(size.width, cut);
    path.lineTo(size.width, size.height - cut);
    path.lineTo(size.width - cut, size.height);
    path.lineTo(cut, size.height);
    path.lineTo(0, size.height - cut);
    path.lineTo(0, cut);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}