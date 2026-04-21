import 'dart:io';

void main() {
  final loginFile = File('lib/screens/login_screen.dart');
  if (loginFile.existsSync()) {
    String content = loginFile.readAsStringSync();
    
    // Fix face login block
    content = content.replaceFirst(
'''      } else if (mounted) {
        AppToast.show(context, 'Yuz aniqlanmadi yoki ruxsat berilmagan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: \$e', isError: true);
      }''',
'''      } else if (mounted) {
        AppToast.show(context, 'Yuz aniqlanmadi yoki ruxsat berilmagan', isError: true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, 'Xatolik: \$e', isError: true);
      }'''
    );
    
    // Fix admin login block
    content = content.replaceFirst(
'''    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login yoki parol noto\\'g\\'ri'),
          backgroundColor: Colors.red,
        ),
      );
    }''',
'''    } else if (mounted) {
      AppToast.show(context, 'Login yoki parol noto\\'g\\'ri', isError: true);
    }'''
    );
    
    loginFile.writeAsStringSync(content);
  }
  
  final profileFile = File('lib/screens/dashboard_views/profile_view.dart');
  if (profileFile.existsSync()) {
    String content = profileFile.readAsStringSync();
    
    content = content.replaceFirst(
'''      if (newPath != null) {
        if (context.mounted) {
          context.read<AuthCubit>().updateImage(newPath);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil rasmi muvaffaqiyatli yangilandi'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rasmni yuklashda xatolik yuz berdi. Server javobini tekshiring.'), backgroundColor: Colors.red),
          );
        }
      }''',
'''      if (newPath != null) {
        if (context.mounted) {
          context.read<AuthCubit>().updateImage(newPath);
          AppToast.show(context, 'Profil rasmi muvaffaqiyatli yangilandi');
        }
      } else {
        if (context.mounted) {
          AppToast.show(context, 'Rasmni yuklashda xatolik yuz berdi. Server javobini tekshiring.', isError: true);
        }
      }'''
    );
    
    content = content.replaceFirst(
'''    if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barcha maydonlarni to\\'ldiring')));
      return;
    }

    if (newPwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yangi parollar mos kelmadi')));
      return;
    }''',
'''    if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
      AppToast.show(context, 'Barcha maydonlarni to\\'ldiring', isError: true);
      return;
    }

    if (newPwd != confirmPwd) {
      AppToast.show(context, 'Yangi parollar mos kelmadi', isError: true);
      return;
    }'''
    );
    
    content = content.replaceFirst(
'''      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );''',
'''      if (mounted) {
        AppToast.show(context, result['message'], isError: !result['success']);'''
    );

    content = content.replaceFirst(
'''      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tizim xatoligi yuz berdi'), backgroundColor: Colors.red));
      }''',
'''      if (mounted) {
        AppToast.show(context, 'Tizim xatoligi yuz berdi', isError: true);
      }'''
    );
    
    profileFile.writeAsStringSync(content);
  }
}
