import 'package:flutter/material.dart';
import 'package:xbeat3/pages/favourites_page.dart';

import '../pages/settings_page.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(child: Center(
            child: Image.asset('assets/images/launchericon.png',)

          )
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListTile(
              leading: Icon(Icons.home, color: Theme.of(context).colorScheme.inversePrimary,),
              title: Text('H O M E', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
              onTap: (){
                Navigator.pop(context);
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListTile(
              leading: Icon(Icons.favorite, color: Theme.of(context).colorScheme.inversePrimary,),
              title: Text('F A V O U R I T E S', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
              onTap: (){
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => FavouritesPage()));
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ListTile(
              leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.inversePrimary,),
              title: Text('S E T T I N G S', style: TextStyle(color: Theme.of(context).colorScheme.inversePrimary),),
              onTap: (){
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
              },
            ),
          ),


        ],
      ),
    );
  }
}
