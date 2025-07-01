import 'package:flutter/material.dart';
import '../../services/voice_service.dart';

class VoiceControlWidget extends StatefulWidget {
  const VoiceControlWidget({super.key});

  @override
  State<VoiceControlWidget> createState() => _VoiceControlWidgetState();
}

class _VoiceControlWidgetState extends State<VoiceControlWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await VoiceService.stopListening();
      _pulseController.stop();
      setState(() => _isListening = false);
    } else {
      final success = await VoiceService.startListening();
      if (success) {
        _pulseController.repeat(reverse: true);
        setState(() => _isListening = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _pulseAnimation.value : 1.0,
          child: FloatingActionButton(
            heroTag: "voice_control_fab",
            onPressed: _toggleListening,
            backgroundColor: _isListening 
                ? colorScheme.error 
                : colorScheme.primary,
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
