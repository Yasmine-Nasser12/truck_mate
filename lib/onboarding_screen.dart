import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_player/video_player.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Empty return trips waste time and money',
      'subtitle': 'Connect. Match. Move.',
      'video': 'assets/videos/truck_empty.mp4',
    },
    {
      'title': 'Smart matching links trucks to suitable shipments.',
      'subtitle': 'Connect. Match. Move.',
      'video': 'assets/videos/smart_matching.mp4',
    },
    {
      'title': 'With us, your cargo always finds its way.',
      'subtitle': 'Connect. Match. Move.',
      'video': 'assets/videos/map_glow.mp4',
      'isLast': true,
    },
  ];

  
  final List<VideoPlayerController> _controllers = [];

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // تهيئة كل الفيديوهات
    for (var page in _pages) {
      final controller = VideoPlayerController.asset(page['video'] as String);
      _controllers.add(controller);

      controller.initialize().then((_) {
        if (mounted) {
          setState(() {});
          controller.setLooping(false); // مش loop عشان قصيرة
        }
      });
    }

    // تشغيل الفيديو الأول تلقائيًا بعد التهيئة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controllers.isNotEmpty && _controllers[0].value.isInitialized) {
        _controllers[0].play();
      }
    });

    // التحكم في التشغيل/الإيقاف عند تغيير الصفحة
    _pageController.addListener(() {
      final newIndex = _pageController.page?.round() ?? 0;
      if (newIndex != _currentPage) {
        setState(() => _currentPage = newIndex);

        for (var i = 0; i < _controllers.length; i++) {
          if (i == newIndex) {
            if (_controllers[i].value.isInitialized) {
              _controllers[i].play();
            }
          } else {
            _controllers[i].pause();
            _controllers[i].seekTo(const Duration(seconds: 0)); // رجع للبداية
          }
        }
      }
    });
  }

  @override
  void dispose() {
    
    for (var controller in _controllers) {
      controller.pause();
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F766E)],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      final controller = _controllers[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 220,
                              margin: const EdgeInsets.only(bottom: 40),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF0EA5E9), Color(0xFF115E59)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2DD4BF).withOpacity(0.35),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: controller.value.isInitialized
                                  ? AspectRatio(
                                      aspectRatio: controller.value.aspectRatio,
                                      child: VideoPlayer(controller),
                                    )
                                  : const Center(child: CircularProgressIndicator()),
                            ),

                            const SizedBox(height: 24),

                            Text(
                              page['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page['subtitle']!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: Color(0xFF2DD4BF),
                      dotColor: Color(0xFF334155),
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 4,
                      spacing: 12,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                  child: GestureDetector(
                    onTap: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Welcome!')),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2DD4BF), Color(0xFF0EA5E9)],
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2DD4BF).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}