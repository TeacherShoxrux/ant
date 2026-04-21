import 'dart:io';

void main() {
  final file = File('lib/screens/login_screen.dart');
  final lines = file.readAsLinesSync();
  
  // Create a new file with the correct lines
  final newLines = <String>[];
  for (var i = 0; i < lines.length; i++) {
    if (i == 78) {
      newLines.add("      } else if (mounted) {");
      newLines.add("        AppToast.show(context, 'Yuz aniqlanmadi yoki ruxsat berilmagan', isError: true);");
      newLines.add("      }");
      newLines.add("    } catch (e) {");
      newLines.add("      if (mounted) {");
      newLines.add("        AppToast.show(context, 'Xatolik: \$e', isError: true);");
      newLines.add("      }");
      newLines.add("    } finally {");
      newLines.add("      if (mounted) setState(() => _isProcessingFace = false);");
      newLines.add("    }");
      
      i = 90; // Skip to line 90 (0-indexed 89 or 90)
    } else if (i == 102) {
      newLines.add("    } else if (mounted) {");
      newLines.add("      AppToast.show(context, 'Login yoki parol noto\\'g\\'ri', isError: true);");
      newLines.add("    }");
      
      i = 108; // Skip the rest of the old snackbar
    } else {
      newLines.add(lines[i]);
    }
  }
  
  file.writeAsStringSync(newLines.join('\n'));
}
