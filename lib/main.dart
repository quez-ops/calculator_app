import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

/// Root widget configuring the application theme and top-level settings.
class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator State Lab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const CalculatorScreen(),
    );
  }
}

/// Main stateful widget managing user interactions and calculator state.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // Authoritative State Variables
  double? _accumulator;           // Stores the ongoing evaluated total
  String? _pendingOperator;       // Active operation waiting for the second operand
  String _currentInput = '0';     // Current value displayed and edited on screen
  bool _awaitingNextOperand = false; // True when next digit should replace current display
  bool _isError = false;          // Tracks error states like division by zero

  /// Appends or initiates digit entry into the current operand.
  void _onDigit(String digit) {
    // Tapping a digit after an error starts fresh
    if (_isError) _reset();

    setState(() {
      if (_awaitingNextOperand) {
        // Starts the next operand instead of appending to the prior number
        _currentInput = digit;
        _awaitingNextOperand = false;
      } else {
        // Prevent leading redundant zeros
        _currentInput = (_currentInput == '0') ? digit : _currentInput + digit;
      }
    });
  }

  /// Handles arithmetic operators (+, −, ×, ÷) using left-to-right chaining.
  void _onOperator(String op) {
    if (_isError) return;

    setState(() {
      double currentVal = double.tryParse(_currentInput) ?? 0.0;

      // Operator replacement rule: '9 + ×' replaces '+' with '×'
      if (_awaitingNextOperand && _pendingOperator != null) {
        _pendingOperator = op;
        return;
      }

      // If this is the first operator, seed the accumulator;
      // otherwise, evaluate the pending operation immediately (left-to-right rule).
      if (_accumulator == null) {
        _accumulator = currentVal;
      } else if (_pendingOperator != null) {
        _compute(currentVal);
      }

      _pendingOperator = op;
      _awaitingNextOperand = true;
    });
  }

  /// Evaluates pending operations without conventional algebraic precedence.
  void _compute(double secondOperand) {
    if (_pendingOperator == null || _accumulator == null) return;
    double first = _accumulator!;

    switch (_pendingOperator) {
      case '+':
        _accumulator = first + secondOperand;
        break;
      case '−':
        _accumulator = first - secondOperand;
        break;
      case '×':
        _accumulator = first * secondOperand;
        break;
      case '÷':
        // Feature 03: Recoverable division-by-zero error handling
        if (secondOperand == 0) {
          _isError = true;
          _currentInput = 'Error: Div by 0';
          _accumulator = null;
          _pendingOperator = null;
          return;
        }
        _accumulator = first / secondOperand;
        break;
    }
    _currentInput = _formatNumber(_accumulator!);
  }

  /// Completes the calculation when equals is pressed.
  void _onEquals() {
    if (_isError || _accumulator == null || _pendingOperator == null) return;

    // Per assignment contract: ignore equals if no new operand was provided
    if (_awaitingNextOperand) return;

    setState(() {
      double currentVal = double.tryParse(_currentInput) ?? 0.0;
      _compute(currentVal);
      _pendingOperator = null;
      _awaitingNextOperand = true; // Next digit entry starts a fresh calculation
    });
  }

  /// Feature 06: Positive / Negative toggle (±).
  void _onToggleSign() {
    if (_isError || _currentInput == '0') return;

    setState(() {
      if (_currentInput.startsWith('-')) {
        _currentInput = _currentInput.substring(1);
      } else {
        _currentInput = '-$_currentInput';
      }

      // Update accumulator if we're currently displaying a running result
      if (_awaitingNextOperand) {
        _accumulator = double.tryParse(_currentInput);
      }
    });
  }

  /// Feature 02: Clear / All Clear (AC) resets all state to default.
  void _reset() {
    setState(() {
      _accumulator = null;
      _pendingOperator = null;
      _currentInput = '0';
      _awaitingNextOperand = false;
      _isError = false;
    });
  }

  /// Cleans up trailing decimal zeros for cleaner integer displays.
  String _formatNumber(double val) {
    if (val == val.toInt().toDouble()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  /// Helper to build consistent, touch-friendly grid buttons.
  Widget _buildBtn(String label, {Color? bg, VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg ?? const Color(0xFF333333),
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(fontSize: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator State Lab'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display area with Semantics for accessibility screen readers
            Expanded(
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(24),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _currentInput,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _isError ? Colors.redAccent : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            // Keypad Grid
            Row(children: [
              _buildBtn('AC', bg: Colors.red[800], onTap: _reset),
              _buildBtn('±', bg: Colors.grey[700], onTap: _onToggleSign),
              _buildBtn('÷', bg: Colors.amber[800], onTap: () => _onOperator('÷')),
            ]),
            Row(children: [
              _buildBtn('7', onTap: () => _onDigit('7')),
              _buildBtn('8', onTap: () => _onDigit('8')),
              _buildBtn('9', onTap: () => _onDigit('9')),
              _buildBtn('×', bg: Colors.amber[800], onTap: () => _onOperator('×')),
            ]),
            Row(children: [
              _buildBtn('4', onTap: () => _onDigit('4')),
              _buildBtn('5', onTap: () => _onDigit('5')),
              _buildBtn('6', onTap: () => _onDigit('6')),
              _buildBtn('−', bg: Colors.amber[800], onTap: () => _onOperator('−')),
            ]),
            Row(children: [
              _buildBtn('1', onTap: () => _onDigit('1')),
              _buildBtn('2', onTap: () => _onDigit('2')),
              _buildBtn('3', onTap: () => _onDigit('3')),
              _buildBtn('+', bg: Colors.amber[800], onTap: () => _onOperator('+')),
            ]),
            Row(children: [
              _buildBtn('0', onTap: () => _onDigit('0')),
              _buildBtn('=', bg: Colors.green[700], onTap: _onEquals),
            ]),
          ],
        ),
      ),
    );
  }
}