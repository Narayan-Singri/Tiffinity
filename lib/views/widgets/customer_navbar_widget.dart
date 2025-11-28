import 'package:flutter/material.dart';
import 'package:Tiffinity/data/notifiers.dart';

class CustomerNavBarWidget extends StatelessWidget {
  const CustomerNavBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: customerSelectedPageNotifier,
      builder: (context, selectedIndex, _) {
        return BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            customerSelectedPageNotifier.value = index;
          },
          selectedItemColor: const Color.fromARGB(255, 27, 84, 78),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        );
      },
    );
  }
}
