import 'dart:io';

void main() {
  final files = [
    'lib/screens/topic_player_screen.dart',
    'lib/screens/quiz_screen.dart',
    'lib/screens/login_screen.dart',
    'lib/screens/dashboard_views/subjects_view.dart',
    'lib/screens/dashboard_views/students_view.dart',
    'lib/screens/dashboard_views/sessions_view.dart',
    'lib/screens/dashboard_views/profile_view.dart',
    'lib/screens/dashboard_views/grades_view.dart',
    'lib/screens/dashboard_views/admins_view.dart',
    'lib/screens/admin_dashboard.dart',
    'lib/presentation/pages/auth/login_page.dart',
  ];

  final importStatement = "import 'package:student_platform_frontend/widgets/app_toast.dart';\n";

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;

    String content = file.readAsStringSync();
    if (!content.contains('ScaffoldMessenger')) continue;

    // Add import if missing
    if (!content.contains('app_toast.dart')) {
      // Find the last import
      final importRegex = RegExp(r"import '.*?';\n");
      final matches = importRegex.allMatches(content);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last;
        content = content.replaceRange(lastMatch.end, lastMatch.end, importStatement);
      } else {
        content = importStatement + content;
      }
    }

    // Replace ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MSG')));
    // with AppToast.show(context, 'MSG');
    
    // Pattern 1: const SnackBar(content: Text('...'))
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const\s*SnackBar\(\s*content:\s*Text\('([^']+)'\)\s*\)\s*\);"),
      (m) => "AppToast.show(context, '${m[1]}');"
    );

    // Pattern 2: SnackBar(content: Text('...')) without const
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\('([^']+)'\)\s*\)\s*\);"),
      (m) => "AppToast.show(context, '${m[1]}');"
    );

    // Pattern 3: SnackBar(content: Text('...'), backgroundColor: Colors.red)
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\('([^']+)'\),\s*backgroundColor:\s*Colors\.red\s*\)\s*\);"),
      (m) => "AppToast.show(context, '${m[1]}', isError: true);"
    );
    
    // Pattern 4: SnackBar(content: Text(variable))
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\(([^)]+)\)\s*\)\s*\);"),
      (m) {
        final innerText = m[1]!;
        // Avoid nested calls if they were already replaced by quotes
        if (innerText.startsWith("'") && innerText.endsWith("'")) {
          return "AppToast.show(context, $innerText);";
        }
        return "AppToast.show(context, $innerText);";
      }
    );

    // Pattern 5: SnackBar(content: Text(variable), backgroundColor: Colors.red)
    content = content.replaceAllMapped(
      RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*(?:const\s*)?SnackBar\(\s*content:\s*Text\(([^)]+)\),\s*backgroundColor:\s*Colors\.red\s*\)\s*\);"),
      (m) => "AppToast.show(context, ${m[1]}, isError: true);"
    );

    // Multi-line formatting might break regex, let's also do a fallback search and replace for specific multi-line instances
    // We will do a generic replacement if any still remain
    
    file.writeAsStringSync(content);
  }
}
