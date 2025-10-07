import 'package:delivery/APIs/Markets/FetchFoodsForMarket.dart';
import 'package:delivery/APIs/Markets/FetchMarket.dart';
import 'package:delivery/pages/myMarket/OrdersListPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

bool isLoading = true;
String marketId = '';

class AssistiveButton extends StatefulWidget {
  final double size;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final VoidCallback? onSalesSummaryTap;
  final VoidCallback? onOrdersTap;
  final Duration autoHideDuration;
  final Duration animationDuration;

  const AssistiveButton({
    Key? key,
    this.size = 60,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.onSalesSummaryTap,
    this.onOrdersTap,
    this.autoHideDuration = const Duration(seconds: 4),
    this.animationDuration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  State<AssistiveButton> createState() => _AssistiveButtonState();

  static void showButton(BuildContext context) {
    final state = context.findAncestorStateOfType<_AssistiveButtonState>();
    state?._showFromEdge();
  }
}

class _AssistiveButtonState extends State<AssistiveButton>
    with TickerProviderStateMixin {
  late Offset position;
  late bool initialized;
  bool isDragging = false;
  bool isHidden = false;
  bool isMenuExpanded = false;
  Timer? autoHideTimer;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _menuController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _menuAnimation;

  static const String _positionKey = 'assistive_button_position';

  Future<void> loadMarket() async {
    try {
      print('⏳ เรียก fetchMyMarket...');
      final market = await fetchMyMarket();
      print('จาก AssistiveButton.dart นะจะ');
      print('✅ market: $market');
      final fetchedFoods = await FetchFoodsForMarket();
      print('✅ foods: $fetchedFoods');

      setState(() {
        if (market != null && fetchedFoods != null) {
          marketId = market['market_id'].toString();
        } else {
          marketId = 'ไม่พบ ID ร้านค้า';
        }
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error in loadMarket: $e');
      setState(() {
        marketId = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    initialized = false;
    position = const Offset(0, 0);

    _slideController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _menuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeOutBack,
    );

    _colorAnimation =
        ColorTween(
          begin: const Color(0xFF34C759),
          end: const Color(0xFF30D158),
        ).animate(
          CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
        );

    _fadeController.value = 1.0;
    _loadSavedPosition();
    _startAutoHideTimer();

    loadMarket();
  }

  @override
  void dispose() {
    autoHideTimer?.cancel();
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedX = prefs.getDouble('${_positionKey}_x');
      final savedY = prefs.getDouble('${_positionKey}_y');

      if (savedX != null && savedY != null) {
        setState(() {
          position = Offset(savedX, savedY);
          initialized = true;
        });
      }
    } catch (e) {
      print('Error loading position: $e');
    }
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${_positionKey}_x', position.dx);
      await prefs.setDouble('${_positionKey}_y', position.dy);
    } catch (e) {
      print('Error saving position: $e');
    }
  }

  void _startAutoHideTimer() {
    autoHideTimer?.cancel();
    autoHideTimer = Timer(widget.autoHideDuration, () {
      if (mounted && !isDragging && !isMenuExpanded) {
        _hideToEdge();
      }
    });
  }

  void _hideToEdge() {
    if (!isHidden) {
      setState(() {
        isHidden = true;
      });
      _slideController.forward();
      _fadeController.forward();
    }
  }

  void _showFromEdge() {
    if (isHidden) {
      setState(() {
        isHidden = false;
      });
      _slideController.reverse();
      _fadeController.reverse();
      _startAutoHideTimer();
    }
  }

  void _toggleMenu() {
    setState(() {
      isMenuExpanded = !isMenuExpanded;
    });

    if (isMenuExpanded) {
      _menuController.forward();
      autoHideTimer?.cancel();
    } else {
      _menuController.reverse();
      _startAutoHideTimer();
    }

    HapticFeedback.mediumImpact();
  }

  void _onDragStart() {
    if (isMenuExpanded) {
      _toggleMenu();
    }
    setState(() {
      isDragging = true;
    });
    autoHideTimer?.cancel();
    _showFromEdge();
    HapticFeedback.lightImpact();
  }

  void _initPosition(Size screen, EdgeInsets safe) {
    if (initialized) return;
    final dx = screen.width - widget.size - 20;
    final bottomMargin = 100.0;
    final topMargin = 60.0;
    final dy = screen.height - widget.size - safe.bottom - bottomMargin;
    final minY = safe.top + topMargin;
    position = Offset(dx, dy < minY ? minY : dy);
    initialized = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!isDragging) {
      _onDragStart();
    }
    setState(() {
      position += details.delta;
    });
  }

  void _onDragEnd(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final safe = media.padding;

    double x = position.dx;
    double y = position.dy;
    final topMargin = -30.0;
    final minY = safe.top + topMargin;
    final bottomMargin = 50.0;
    final maxY = screen.height - widget.size - safe.bottom - bottomMargin;
    if (y < minY) y = minY;
    if (y > maxY) y = maxY;

    final centerX = x + widget.size / 2;
    final margin = 2.0;
    final snapLeft = margin;
    final snapRight = screen.width - widget.size - margin;
    final targetX = (centerX < screen.width / 2) ? snapLeft : snapRight;

    setState(() {
      position = Offset(targetX, y);
      isDragging = false;
    });

    _savePosition();
    HapticFeedback.mediumImpact();
    _startAutoHideTimer();
  }

  void _onTap() {
    _showFromEdge();
    HapticFeedback.selectionClick();
    _toggleMenu();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    _initPosition(media.size, media.padding);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _slideController,
        _fadeController,
        _pulseController,
        _glowController,
        _menuController,
      ]),
      builder: (context, child) {
        final screen = media.size;
        final isOnLeftSide = position.dx < screen.width / 2;

        double hideOffset = 0;
        if (isHidden) {
          hideOffset = isOnLeftSide
              ? -(widget.size * 0.52) * _slideAnimation.value
              : (widget.size * 0.52) * _slideAnimation.value;
        }

        final opacity = isHidden
            ? 0.3 + (0.5 * (1 - _fadeAnimation.value))
            : 1.0;

        final glowColor = _colorAnimation.value ?? const Color(0xFF34C759);

        return Stack(
          children: [
            // Menu items
            if (isMenuExpanded) _buildMenuItems(isOnLeftSide),

            // Main button
            Positioned(
              left: position.dx + hideOffset,
              top: position.dy,
              child: SafeArea(
                child: GestureDetector(
                  onPanStart: (_) => _onDragStart(),
                  onPanUpdate: _onDragUpdate,
                  onPanEnd: (_) => _onDragEnd(context),
                  onTap: _onTap,
                  child: Transform.scale(
                    scale: isDragging ? 1.15 : _pulseAnimation.value,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (!isHidden && !isDragging)
                              Container(
                                width: widget.size + 20,
                                height: widget.size + 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: glowColor.withOpacity(
                                        0.4 * _glowAnimation.value,
                                      ),
                                      blurRadius:
                                          25 + (15 * _glowAnimation.value),
                                      spreadRadius:
                                          3 + (4 * _glowAnimation.value),
                                    ),
                                  ],
                                ),
                              ),
                            Container(
                              width: widget.size,
                              height: widget.size,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    glowColor,
                                    glowColor.withOpacity(0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDragging ? 0.3 : 0.2,
                                    ),
                                    blurRadius: isDragging ? 20 : 12,
                                    offset: Offset(0, isDragging ? 10 : 6),
                                    spreadRadius: isDragging ? 3 : 1,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Material(
                                  color: Colors.transparent,
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      transitionBuilder: (child, animation) {
                                        return RotationTransition(
                                          turns: Tween<double>(
                                            begin: 0.0,
                                            end: 0.25,
                                          ).animate(animation),
                                          child: ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        isMenuExpanded
                                            ? Icons.close_rounded
                                            : isHidden
                                            ? Icons.touch_app_rounded
                                            : Icons.apps_rounded,
                                        key: ValueKey(
                                          isMenuExpanded
                                              ? 'close'
                                              : isHidden
                                              ? 'touch'
                                              : 'apps',
                                        ),
                                        color: Colors.white,
                                        size: widget.size * 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItems(bool isOnLeftSide) {
    return Positioned(
      left: isOnLeftSide ? position.dx + widget.size + 16 : position.dx - 180,
      top: position.dy - 80,
      child: ScaleTransition(
        scale: _menuAnimation,
        alignment: isOnLeftSide ? Alignment.centerLeft : Alignment.centerRight,
        child: FadeTransition(
          opacity: _menuAnimation,
          child: Column(
            crossAxisAlignment: isOnLeftSide
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMenuItem(
                icon: Icons.food_bank_rounded,
                label: 'ร้านค้า',
                color: const Color(0xFF007AFF),
                onTap: () async {
                  _toggleMenu();
                  print('✅ กดเมนูร้านค้าแล้ว');

                  if (widget.onSalesSummaryTap != null) {
                    widget.onSalesSummaryTap!();
                  } else if (marketId != '') {
                    final result = await Navigator.pushNamed(
                      context,
                      '/myMarket',
                    );
                    print('markets result: $result');
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.bar_chart_rounded,
                label: 'สรุปยอดขาย',
                color: const Color(0xFF007AFF),
                onTap: () async {
                  _toggleMenu();
                  print('✅ กดเมนูสรุปยอดขายแล้ว');

                  if (widget.onSalesSummaryTap != null) {
                    widget.onSalesSummaryTap!();
                  } else if (marketId != '') {
                    final result = await Navigator.pushNamed(
                      context,
                      '/dashboard-sales',
                      arguments: {'marketId': int.tryParse(marketId) ?? 0},
                    );
                    print('Dashboard Sales result: $result');
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.work_outline_rounded,
                label: 'รับงาน',
                color: const Color(0xFFFF9500),
                onTap: () async {
                  _toggleMenu();
                  print('✅ กดเมนูรับงานแล้ว');
                  if (widget.onOrdersTap != null) {
                    widget.onOrdersTap!();
                  } else if (marketId != '') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrdersListPage(
                          marketId: int.tryParse(marketId) ?? 0,
                        ),
                      ),
                    );
                    print('OrdersListPage result: $result');
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: Icons.help_outline_rounded,
                label: 'ช่วยเหลือ',
                color: const Color(0xFF5856D6),
                onTap: () {
                  _toggleMenu();
                  _showHelpDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        // fixed width so all menu items are the same size
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  // ensure no underline and consistent text appearance
                  decoration: TextDecoration.none,
                  color: Colors.grey.shade800,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF5856D6), const Color(0xFF7B79F5)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'วิธีใช้งาน',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              Icons.touch_app_rounded,
              'แตะเพื่อเปิดเมนูด่วน',
              const Color(0xFF34C759),
            ),
            const SizedBox(height: 14),
            _buildHelpItem(
              Icons.drag_indicator_rounded,
              'ลากเพื่อย้ายตำแหน่ง',
              const Color(0xFFFF9500),
            ),
            const SizedBox(height: 14),
            _buildHelpItem(
              Icons.visibility_off_rounded,
              'ปุ่มจะซ่อนอัตโนมัติใน ${widget.autoHideDuration.inSeconds} วินาที',
              const Color(0xFF007AFF),
            ),
            const SizedBox(height: 14),
            _buildHelpItem(
              Icons.bookmark_rounded,
              'ตำแหน่งจะถูกบันทึกอัตโนมัติ',
              const Color(0xFF5856D6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF34C759),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'เข้าใจแล้ว',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
