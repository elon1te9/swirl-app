import 'package:flutter/material.dart';
import 'package:swirl_app/app/theme.dart';

import '../../app/router.dart';
import '../widgets/screen_placeholder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _streakDays = 10;
  final String _userName = 'Милена';

  Widget userHeaderPanel() {
    final chipDecoration = BoxDecoration(
      color: const Color.fromRGBO(39, 35, 58, 0.8),
      borderRadius: BorderRadius.circular(20),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: chipDecoration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color.fromRGBO(151, 219, 255, 1),
                  child: const Text(
                    //ЗАГЛУШКАААААААААААААААААААААААААААААААААААААААААААААААААААААААААААААААААААААА
                    '🐱',
                    style: TextStyle(fontSize: 14),
                  ),
                ),

                const SizedBox(width: 8),
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: chipDecoration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_streakDays',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('🔥', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget seriesPanel() {
    final daysOfWeek = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    const currentDayIndex = 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Серия',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(39, 35, 58, 0.8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(
                      '$_streakDays дней',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                Row(
                  children: List.generate(7, (index) {
                    final isCompleted = index < currentDayIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? const Color.fromRGBO(151, 219, 255, 1)
                                  : Colors.transparent,
                              border: Border.all(
                                color: const Color.fromRGBO(151, 219, 255, 1),
                                width: 2,
                              ),
                            ),
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            daysOfWeek[index],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget continueLearningPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Продолжить обучение',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(215, 38, 61, 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Image.asset(
                  'images/sections/food_continue_learn.png',
                  height: 100,
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Food',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Уровень 2 - Легкий',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: const LinearProgressIndicator(
                                value: 14 / 30, // Текущий прогресс
                                backgroundColor: Color.fromRGBO(
                                  255,
                                  255,
                                  255,
                                  0.5,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.fromRGBO(151, 219, 255, 1),
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '14/30',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.navigate_next,
                    color: Color(0xFFD92E43),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionCard({
    required String title,
    required String levels,
    required String progressText,
    required double progressValue,
    required Color backgroundColor,
    required Color textColor,
    required Color progressColor,
    required Color progressBgColor,
    required String imagePath,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Image.asset(imagePath, height: 60),

            const SizedBox(height: 12),

            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(levels, style: TextStyle(color: textColor, fontSize: 11)),
            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: progressBgColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),

            Text(
              progressText,
              style: TextStyle(color: textColor, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionsPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Разделы',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              sectionCard(
                title: 'Food',
                levels: '5 уровней',
                progressText: '1/5',
                progressValue: 1 / 5,
                backgroundColor: Color.fromRGBO(215, 38, 61, 1),
                textColor: Colors.white,
                progressColor: Color.fromRGBO(151, 219, 255, 1),
                progressBgColor: Color.fromRGBO(255, 255, 255, 0.5),
                imagePath: 'images/sections/food.png',
              ),
              const SizedBox(width: 10),

              sectionCard(
                title: 'Science',
                levels: '5 уровней',
                progressText: '0/5',
                progressValue: 0.0,
                backgroundColor: Color.fromRGBO(215, 38, 61, 1),
                textColor: Colors.white,
                progressColor: Color.fromRGBO(151, 219, 255, 1),
                progressBgColor: Color.fromRGBO(255, 255, 255, 0.5),
                imagePath: 'images/sections/food.png',
              ),
              const SizedBox(width: 10),

              sectionCard(
                title: 'Health',
                levels: '5 уровней',
                progressText: '0/5',
                progressValue: 0.0,
                backgroundColor: Color.fromRGBO(215, 38, 61, 1),
                textColor: Colors.white,
                progressColor: Color.fromRGBO(151, 219, 255, 1),
                progressBgColor: Color.fromRGBO(255, 255, 255, 0.5),
                imagePath: 'images/sections/food.png',
              ),
            ],
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Все разделы ',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 12,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(111, 115, 210, 1),
      body: SafeArea(
        child: Column(
          children: [
            userHeaderPanel(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Привет!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          'Готов изучать новые слова?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Image.asset(
                          'images/mascot_home.png',
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),

                    seriesPanel(),

                    continueLearningPanel(),

                    sectionsPanel(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
