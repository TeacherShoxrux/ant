import 'dart:io';

void main() {
  final files = [
    'lib/screens/topic_player_screen.dart',
    'lib/screens/quiz_screen.dart',
    'lib/screens/login_screen.dart',
    'lib/screens/dashboard_views/subjects_view.dart',
    'lib/screens/dashboard_views/sessions_view.dart',
    'lib/screens/dashboard_views/profile_view.dart',
    'lib/screens/dashboard_views/grades_view.dart',
    'lib/screens/dashboard_views/admins_view.dart',
    'lib/presentation/pages/auth/login_page.dart',
  ];

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;

    String content = file.readAsStringSync();
    
    // SnackBar(content: Text('MSG'), backgroundColor: Colors.green)
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*Colors\.green\s*\)\s*,\s*\);", dotAll: true),
      (m) => "AppToast.show(context, ${m[1]});"
    );
    
    // SnackBar(content: Text('MSG'), backgroundColor: Colors.red)
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*Colors\.red\s*\)\s*,\s*\);", dotAll: true),
      (m) => "AppToast.show(context, ${m[1]}, isError: true);"
    );
    
    // SnackBar(content: Text('MSG'), backgroundColor: Colors.red) without trailing comma
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*Colors\.red\s*\)\s*\);", dotAll: true),
      (m) => "AppToast.show(context, ${m[1]}, isError: true);"
    );
    
    // SnackBar(content: Text('MSG'), backgroundColor: Colors.green) without trailing comma
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\((.*?)\),\s*backgroundColor:\s*Colors\.green\s*\)\s*\);", dotAll: true),
      (m) => "AppToast.show(context, ${m[1]});"
    );

    // SnackBar(content: Text('MSG'))
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\((.*?)\)\s*\)\s*,\s*\);", dotAll: true),
      (m) => "AppToast.show(context, ${m[1]});"
    );
    
    // SnackBar(content: Text('MSG')) without trailing comma
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\((.*?)\)\s*\)\s*\);", dotAll: true),
      (m) => "AppToast.show(context, ${m[1]});"
    );
    
    // SnackBar(content: Text('MSG', ...)) -> edge cases
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\('Baho maksimal balldan \(\$maxScore\) yuqori bo\\'lishi mumkin emas.'\)\)\);", dotAll: true),
      (m) => "AppToast.show(context, 'Baho maksimal balldan (\$maxScore) yuqori bo\\'lishi mumkin emas.');"
    );

    file.writeAsStringSync(content);
  }
}
