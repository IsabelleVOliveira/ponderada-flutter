import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget {
  final VoidCallback? onDebugReload;
  
  const HeaderWidget({
    super.key,
    this.onDebugReload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 60, 15, 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF0F0F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.restaurant,
            size: 34,
            color: Color(0xFFFF69B4),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Receitas de Família',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF69B4),
              ),
            ),
          ),
          if (onDebugReload != null)
            IconButton(
              onPressed: onDebugReload,
              icon: const Icon(
                Icons.refresh,
                color: Color(0xFFFF69B4),
              ),
              tooltip: 'Recarregar receitas',
            ),
        ],
      ),
    );
  }
} 