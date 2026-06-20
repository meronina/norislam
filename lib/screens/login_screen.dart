import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isRegisterMode = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      User? user;

      if (_isRegisterMode) {
        user = await _auth.registerWithEmail(email, password);
      } else {
        user = await _auth.signInWithEmail(email, password);
      }

      if (!mounted) return;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = '❌ البريد الإلكتروني غير مسجل.';
          break;
        case 'wrong-password':
          message = '❌ كلمة المرور غير صحيحة.';
          break;
        case 'email-already-in-use':
          message = '❌ هذا البريد مستخدم سابقاً.';
          break;
        case 'invalid-email':
          message = '❌ البريد الإلكتروني غير صالح.';
          break;
        case 'weak-password':
          message = '❌ كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
          break;
        default:
          message = '❌ حدث خطأ: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ غير متوقع: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      final user = await _auth.signInAnonymously();
      if (!mounted) return;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'operation-not-allowed') {
        message =
            '⚠️ المصادقة المجهولة غير مفعلة في Firebase.\nالرجاء تفعيلها من Firebase Console.';
      } else {
        message = '❌ فشل الدخول: ${e.message}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(message), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ غير متوقع: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'الرجاء إدخال البريد الإلكتروني لإعادة تعيين كلمة المرور.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('تم إرسال رابط إعادة التعيين إلى البريد الإلكتروني.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ غير متوقع: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mosque, size: 90, color: Colors.teal),
              const SizedBox(height: 24),
              const Text(
                'أهلاً بك في أسئلة دينية',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'اختر طريقة الدخول المفضلة لديك، أو جرّب التطبيق كزائر.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'الرجاء إدخال البريد الإلكتروني.';
                            }
                            if (!value.contains('@')) {
                              return 'الرجاء إدخال بريد إلكتروني صالح.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: Icon(Icons.lock_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'الرجاء إدخال كلمة المرور.';
                            }
                            if (value.trim().length < 6) {
                              return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
                            }
                            return null;
                          },
                        ),
                        if (_isRegisterMode) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'تأكيد كلمة المرور',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            validator: (value) {
                              if (_isRegisterMode) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'الرجاء تأكيد كلمة المرور.';
                                }
                                if (value.trim() !=
                                    _passwordController.text.trim()) {
                                  return 'كلمة المرور غير متطابقة.';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _submit,
                                icon: Icon(_isRegisterMode
                                    ? Icons.app_registration_rounded
                                    : Icons.login_rounded),
                                label: Text(_isRegisterMode
                                    ? 'إنشاء حساب'
                                    : 'تسجيل الدخول'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _sendPasswordReset,
                                child: const Text('نسيت كلمة المرور؟'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegisterMode = !_isRegisterMode;
                  });
                },
                child: Text(_isRegisterMode
                    ? 'لديك حساب؟ تسجيل الدخول'
                    : 'ليس لديك حساب؟ أنشئ حسابًا'),
              ),
              const SizedBox(height: 16),
              const Text('أو'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _signInAnonymously,
                icon: const Icon(Icons.person_off),
                label: const Text('ابدأ كمستخدم زائر'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
