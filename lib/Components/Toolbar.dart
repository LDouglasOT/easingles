import 'package:flutter/material.dart';
import 'package:mazale/Provider/SocketProvider.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:provider/provider.dart';

class Toolbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color background;
  final List<Widget>? actions;
  final Widget? leading;
  const Toolbar(
      {super.key,
      required this.title,
      this.actions,
      this.leading,
      required this.background});

  @override
  Widget build(BuildContext context) {
    return AppBar(
        leading: leading,
        title: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: 15,
            ),
          ],
        ),
        // backgroundColor: const Color.fromARGB(255, 97, 119, 161),
        backgroundColor: AppColors.lighter,
        centerTitle: false,
        actions: actions);
  }

  @override
  // TODO: implement preferredSize
  Size get preferredSize => const Size.fromHeight(60);
}
