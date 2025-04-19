import 'package:cod_hammer/widgets/bet_overlay.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import '../widgets/betting_widget.dart';
import '../widgets/team_info_overlay.dart';

class BetPage extends StatefulWidget {
  const BetPage({Key? key}) : super(key: key);

  @override
  State<BetPage> createState() => _BetPageState();
}

class _BetPageState extends State<BetPage> {
  late VideoPlayerController _videoController;
  bool _isFullScreen = false;
  bool _isRussian = true; // Состояние для переключения языка

  String get currentFontFamily {
    return _isRussian ? 'Cornerita' : 'Tomorrow';
  }

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
    return GestureDetector(
      onTap: () {
        setState(() {
          _isRussian = !_isRussian; // Переключаем язык при нажатии
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF062B42),
        body: _isFullScreen ? _buildFullScreenVideo() : _buildMainContent(),
      ),
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _buildHeader(constraints.maxWidth),
              const SizedBox(height: 30),
              _buildVideoPlayer(constraints.maxWidth),
              const SizedBox(height: 30),
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(double maxWidth) {
    return Column(
      children: [
        Text(
          _isRussian ? 'Битва роботов в Москве \nбитва между Русскими' : 'Roboport of Moscow\nBattle of the Russians',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFCDFBE4),
            fontSize: (maxWidth / 6 < 18) ? maxWidth / 6 : 18,
            fontFamily: currentFontFamily, // Используем пользовательский шрифт
          ),
        ),
        const SizedBox(height: 20),
        BettingWidget(
          firstRobotPercentage: 75.0,
          secondRobotPercentage: 25.0,
          firstRobotCoefficient: 1.25,
          secondRobotCoefficient: 3.50,
          matchTime: "18:00",
          firstTeamName: _isRussian ? 'WEBER LABS' : 'WEBER LABS ',
          secondTeamName: _isRussian ? 'Auxilium AI' : 'Auxilium AI ',
          onFirstRobotTap: () {
            _showBetOverlay(context, coefficient: 1.25, teamName: _isRussian ? 'WEBER LABS' : 'WEBER LABS ', isFirstTeam: true);
          },
          onSecondRobotTap: () {
            _showBetOverlay(context, coefficient: 3.50, teamName: _isRussian ? 'Auxilium AI' : 'Auxilium AI ', isFirstTeam: false);
          },
          onFirstTeamImageTap: () {
            _showTeamInfoOverlay(
              context,
              teamName: _isRussian ? 'WEBER LABS' : 'WEBER LABS ',
              teamMembers: _isRussian
                  ? [
                      'Алексей Орлеанский',
                      'Шмелев Александр',
                      'Жуков Дмитрий',
                      'Просужих Александр',
                      'Россия/Москва',
                    ]
                  : [
                      'Alexey d\'Orléans ',
                      'Shmelev Alexander ',
                      'Zhukov Dmitry ',
                      'Progesch Alexander ',
                      'Russia/Moscow ',
                    ],
              robotName: _isRussian ? 'Робот Колобаха' : 'Robot - Kolobah ',
              robotDetails: _isRussian
                  ? 'Вертикальная конструкция спиннера RU\вес робота 110(кг)\nSpeed 26 км/ч\nDimensions 630*740*330'
                  : 'Vertical spinner construction EN\nweight of the robot 110(kg)\nSpeed 26 km/h\nDimensions 630*740*330',
              imageUrl: 'assets/weber.png',
              teamColor: const Color(0xFFCDFBE4), // Зеленый для первой команды
            );
          },
          onSecondTeamImageTap: () {
            _showTeamInfoOverlay(
              context,
              teamName: _isRussian ? 'Auxilium AI' : 'Auxilium AI ',
              teamMembers: _isRussian
                  ? [
                      'Ледюков Алексей',
                      'Петриков Федор',
                      'Захаров Дмитрий',
                      'Яременко Андрей',
                      'Смирнов Иван',
                      'Russia/Saint Petersburg',
                    ]
                  : [
                      'Ledyukov Alexey ',
                      'Petrikov Fedor ',
                      'Zakharov Dmitry ',
                      'Yasemenko Ivan ',
                      'Smirnov Ivan ',
                      'Russia/Saint Petersburg ',
                    ],
              robotName: _isRussian ? 'Robot - A.L.F.A' : 'Robot - A.L.F.A ',
              robotDetails: _isRussian
                  ? 'Вертикальная конструкция спиннера вес робота 160(кг)\nSpeed 25 км/ч\nDimensions 1200*1200*340'
                  : 'Vertical spinner construction EN\nweight of the robot 160(kg)\nSpeed 25 km/h\nDimensions 1200*1200*340',
              imageUrl: 'assets/au.jpg',
              teamColor: const Color(0xFFFAEFD9), // Желтый для второй команды
            );
          },
        ),
      ],
    );
  }

  Widget _buildVideoPlayer(double maxWidth) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFullScreen = true;
        });
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      },
      child: Container(
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
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        _buildContactInfo(_isRussian ? 'На общие вопросы' : 'On general matters', 'info@bitva-robotov.ru'),
        _buildContactInfo(_isRussian ? 'По участию' : 'On participation', 'team@bitva-robotov.ru'),
      ],
    );
  }

  Widget _buildContactInfo(String title, String email) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFFCDFBE4),
            fontSize: 16,
            fontFamily: currentFontFamily, // Используем пользовательский шрифт
          ),
        ),
        GestureDetector(
          onTap: () {
            print('Clicked on $email');
          },
          child: Text.rich(
            TextSpan(
              text: email,
              style: TextStyle(
                color: const Color.fromRGBO(216, 204, 255, 1),
                fontSize: 16,
                fontFamily: currentFontFamily, // Используем пользовательский шрифт
                decoration: TextDecoration.underline,
                decorationColor: const Color.fromRGBO(216, 204, 255, 1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
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

  void _showBetOverlay(BuildContext context,
      {required double coefficient, required String teamName, required bool isFirstTeam}) {
    showDialog(
      context: context,
      builder: (context) {
        return BetOverlay(
          teamName: teamName,
          coefficient: coefficient,
          isFirstTeam: isFirstTeam,
          fontFamily: currentFontFamily, // Передаем шрифт в BetOverlay
        );
      },
    );
  }

  void _showTeamInfoOverlay(BuildContext context,
      {required String teamName,
      required List<String> teamMembers,
      required String robotName,
      required String robotDetails,
      required String imageUrl,
      required Color teamColor}) {
    showDialog(
      context: context,
      builder: (context) {
        return TeamInfoOverlay(
          teamName: teamName,
          teamMembers: teamMembers,
          robotName: robotName,
          robotDetails: robotDetails,
          imageUrl: imageUrl,
          teamColor: teamColor,
          
        );
      },
    );
  }
}

class OctagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final double cut = size.width / 6;

    path.moveTo(cut, 0);
    path.lineTo(size.width - cut, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cut);
    path.lineTo(size.width, size.height - cut);
    path.quadraticBezierTo(size.width, size.height, size.width - cut, size.height);
    path.lineTo(cut, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - cut);
    path.lineTo(0, cut);
    path.quadraticBezierTo(0, 0, cut, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}