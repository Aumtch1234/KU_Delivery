import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AssistiveButton extends StatefulWidget {
  final double size;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Duration autoHideDuration;
  final Duration animationDuration;

  const AssistiveButton({
    Key? key,
    this.size = 60,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.autoHideDuration = const Duration(seconds: 4),
    this.animationDuration = const Duration(milliseconds: 400),
  }) : super(key: key);

  @override
  State<AssistiveButton> createState() => _AssistiveButtonState();

  // สร้าง static method เพื่อใช้จากภายนอก
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
  Timer? autoHideTimer;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _colorAnimation;

  // Key สำหรับ SharedPreferences
  static const String _positionKey = 'assistive_button_position';

  @override
  void initState() {
    super.initState();
    initialized = false;
    position = const Offset(0, 0);

    // สร้าง animation controllers
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

    // สร้าง animations
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _colorAnimation =
        ColorTween(
          begin: Colors.blue.shade400,
          end: Colors.purple.shade400,
        ).animate(
          CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
        );

    // เริ่มต้น fade controller
    _fadeController.value = 1.0;

    // ไม่เริ่ม pulse และ glow animation อัตโนมัติ

    // โหลดตำแหน่งที่บันทึกไว้
    _loadSavedPosition();

    // เริ่มต้นการซ่อนอัตโนมัติ
    _startAutoHideTimer();
  }

  @override
  void dispose() {
    autoHideTimer?.cancel();
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
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
      // ถ้าเกิดข้อผิดพลาดในการโหลด ใช้ตำแหน่งเริ่มต้น
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
      if (mounted && !isDragging) {
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

  void _onDragStart() {
    setState(() {
      isDragging = true;
    });
    autoHideTimer?.cancel();
    _showFromEdge();
    // เพิ่ม haptic feedback เมื่อเริ่มเลื่อน
    HapticFeedback.lightImpact();
  }

  void _initPosition(Size screen, EdgeInsets safe) {
    if (initialized) return;
    // default bottom-right (ชิดขอบจอมากที่สุด)
    final dx = screen.width - widget.size - 20; // เพิ่ม margin
    final bottomMargin = 100.0; // เพิ่ม margin ล่าง
    final topMargin = 60.0; // เพิ่ม margin บน
    final dy = screen.height - widget.size - safe.bottom - bottomMargin;

    // clamp ไม่ให้ต่ำกว่าขอบบน
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

    // clamp ตำแหน่ง Y
    double x = position.dx;
    double y = position.dy;
    final topMargin = -30.0; // ลด margin บน
    final minY = safe.top + topMargin;
    final bottomMargin = 50.0; // ลด margin ล่าง
    final maxY = screen.height - widget.size - safe.bottom - bottomMargin;
    if (y < minY) y = minY;
    if (y > maxY) y = maxY;

    // snap horizontally to nearest edge (ชิดขอบจอมากขึ้น)
    final centerX = x + widget.size / 2;
    final margin = 2.0; // ลด margin จากขอบให้ชิดมากขึ้น
    final snapLeft = margin;
    final snapRight = screen.width - widget.size - margin;
    final targetX = (centerX < screen.width / 2) ? snapLeft : snapRight;

    setState(() {
      position = Offset(targetX, y);
      isDragging = false;
    });

    // บันทึกตำแหน่งใหม่
    _savePosition();

    // เพิ่ม haptic feedback เมื่อ snap
    HapticFeedback.mediumImpact();

    // เริ่มต้นการซ่อนอัตโนมัติใหม่
    _startAutoHideTimer();
  }

  void _onTap() {
    _showFromEdge();
    // เพิ่ม haptic feedback เมื่อแตะ
    HapticFeedback.selectionClick();

    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      _showHelpDialog(context);
    }
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
      ]),
      builder: (context, child) {
        final screen = media.size;
        final isOnLeftSide = position.dx < screen.width / 2;

        // คำนวดตำแหน่งที่จะซ่อน (ซ่อนแนบขอบจอ)
        double hideOffset = 0;
        if (isHidden) {
          hideOffset = isOnLeftSide
              ? -(widget.size * 0.52) *
                    _slideAnimation
                        .value // ซ่อนไปทางซ้าย 52%
              : (widget.size * 0.52) *
                    _slideAnimation.value; // ซ่อนไปทางขวา 52%
        }

        // คำนวด opacity ที่จะเปลี่ยนแปลง
        final opacity = isHidden
            ? 0.3 +
                  (0.5 * (1 - _fadeAnimation.value)) // เฟดเป็น 0.3-0.8
            : 1.0;

        // สี gradient สำหรับ glow effect
        final glowColor = _colorAnimation.value ?? Colors.blue.shade400;

        return Positioned(
          left: position.dx + hideOffset,
          top: position.dy,
          child: SafeArea(
            child: GestureDetector(
              onPanStart: (_) => _onDragStart(),
              onPanUpdate: _onDragUpdate,
              onPanEnd: (_) => _onDragEnd(context),
              onTap: _onTap,
              child: Transform.scale(
                scale: isDragging
                    ? 1.15
                    : isHidden
                    ? 1.0
                    : _pulseAnimation.value, // Pulse เมื่อไม่ซ่อน
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect ด้านหลัง
                        if (!isHidden && !isDragging)
                          Container(
                            width: widget.size + 20,
                            height: widget.size + 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: glowColor.withOpacity(
                                    0.3 * _glowAnimation.value,
                                  ),
                                  blurRadius: 20 + (10 * _glowAnimation.value),
                                  spreadRadius: 2 + (3 * _glowAnimation.value),
                                ),
                              ],
                            ),
                          ),

                        // ปุ่มหลัก
                        Container(
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Colors.grey.shade50],
                            ),
                            border: Border.all(
                              color: glowColor.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDragging ? 0.25 : 0.15,
                                ),
                                blurRadius: isDragging ? 15 : 8,
                                offset: Offset(0, isDragging ? 8 : 4),
                                spreadRadius: isDragging ? 2 : 0,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 5,
                                // offset: Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Material(
                              color: Colors.transparent,
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Icon หลัก
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      transitionBuilder: (child, animation) {
                                        return RotationTransition(
                                          turns: animation,
                                          child: ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Icon(
                                        isHidden
                                            ? Icons.touch_app_rounded
                                            : Icons.help_outline_rounded,
                                        key: ValueKey(isHidden),
                                        color: glowColor,
                                        size: widget.size * 0.45,
                                      ),
                                    ),

                                    // จุดแจ้งเตือนเมื่อซ่อนอยู่
                                    if (isHidden)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              gradient: RadialGradient(
                                                colors: [
                                                  Colors.orange.shade400,
                                                  Colors.red.shade400,
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.orange
                                                      .withOpacity(0.6),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ],
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: Colors.blue.shade600,
                size: 24,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'ช่วยเหลือ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
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
              'แตะเพื่อเปิดเมนูช่วยเหลือ',
              Colors.green,
            ),
            SizedBox(height: 12),
            _buildHelpItem(
              Icons.drag_indicator_rounded,
              'ลากเพื่อย้ายตำแหน่ง',
              Colors.orange,
            ),
            SizedBox(height: 12),
            _buildHelpItem(
              Icons.visibility_off_rounded,
              'ปุ่มจะซ่อนอัตโนมัติใน ${widget.autoHideDuration.inSeconds} วินาที',
              Colors.blue,
            ),
            SizedBox(height: 12),
            _buildHelpItem(
              Icons.save_rounded,
              'ตำแหน่งจะถูกบันทึกอัตโนมัติ',
              Colors.purple,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.check_rounded),
            label: Text(
              'เข้าใจแล้ว',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
