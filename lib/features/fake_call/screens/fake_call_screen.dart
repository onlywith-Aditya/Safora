import 'dart:async';
import 'package:flutter/material.dart';

class FakeCallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;
  final String callerInitial;

  const FakeCallScreen({
    super.key,
    this.callerName = 'Dad',
    this.callerNumber = 'Mobile • India',
    this.callerInitial = 'D',
  });

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen>
    with SingleTickerProviderStateMixin {
  bool _isCallActive = false;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  late AnimationController _ringAnimationController;

  @override
  void initState() {
    super.initState();
    _ringAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _ringAnimationController.dispose();
    super.dispose();
  }

  void _acceptCall() {
    setState(() {
      _isCallActive = true;
    });
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  void _declineOrEndCall() {
    _callTimer?.cancel();
    Navigator.pop(context);
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Caller Header
              Column(
                children: [
                  const SizedBox(height: 30),
                  Text(
                    widget.callerNumber,
                    style: const TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Circular Caller Avatar with Subtle Pulse
                  AnimatedBuilder(
                    animation: _ringAnimationController,
                    builder: (context, child) {
                      return Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF424242),
                          boxShadow: _isCallActive
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.white.withValues(
                                      alpha: 0.08 * _ringAnimationController.value,
                                    ),
                                    blurRadius: 30,
                                    spreadRadius: 10 * _ringAnimationController.value,
                                  ),
                                ],
                        ),
                        child: Center(
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4F4F4F),
                            ),
                            child: Center(
                              child: Text(
                                widget.callerInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Caller Name
                  Text(
                    widget.callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Call Status
                  Text(
                    _isCallActive
                        ? _formatDuration(_callDurationSeconds)
                        : 'incoming call...',
                    style: TextStyle(
                      color: _isCallActive ? const Color(0xFF2ECC71) : const Color(0xFFC4C4C4),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),

              // Bottom Actions (Decline / Accept or In-Call Actions)
              _isCallActive ? _buildInCallControls() : _buildIncomingCallControls(),
            ],
          ),
        ),
      ),
    );
  }

  /// Incoming Call Controls (Red Decline & Green Accept matching screenshot)
  Widget _buildIncomingCallControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decline Button
          Column(
            children: [
              GestureDetector(
                onTap: _declineOrEndCall,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF1B2D),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x66FF1B2D),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Decline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Accept Button
          Column(
            children: [
              GestureDetector(
                onTap: _acceptCall,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECC71),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x662ECC71),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.call,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Accept',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Active In-Call Controls
  Widget _buildInCallControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInCallIconButton(Icons.mic_off_outlined, 'Mute'),
              _buildInCallIconButton(Icons.dialpad_rounded, 'Keypad'),
              _buildInCallIconButton(Icons.volume_up_rounded, 'Speaker'),
            ],
          ),
          const SizedBox(height: 36),
          // End Call Button
          GestureDetector(
            onTap: _declineOrEndCall,
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFF1B2D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end,
                color: Colors.white,
                size: 34,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInCallIconButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFC4C4C4), fontSize: 12),
        ),
      ],
    );
  }
}
