import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final List<_Message> _messages = [
    _Message(sender: 'Dra. Gómez', text: 'Recuerda tu cita el jueves a las 10:00.', time: DateTime.now().subtract(const Duration(minutes: 12)), unread: true),
    _Message(sender: 'Clínica Central', text: 'Resultados disponibles en tu perfil.', time: DateTime.now().subtract(const Duration(hours: 5)), unread: false),
    _Message(sender: 'Laboratorio', text: 'Tu examen fue procesado correctamente.', time: DateTime.now().subtract(const Duration(days: 1)), unread: false),
    _Message(sender: 'Soporte', text: 'Hemos actualizado la política de privacidad.', time: DateTime.now().subtract(const Duration(days: 3)), unread: true),
  ];

  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _messages.where((m) => m.sender.toLowerCase().contains(_search.toLowerCase()) || m.text.toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.background, theme.colorScheme.surface],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSearchField(theme),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'compose',
                    onPressed: () {
                      // acción para componer mensaje — placeholder
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Componer mensaje')));
                    },
                    child: const Icon(Icons.edit, size: 18),
                  )
                ],
              ),
            ),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text('No hay mensajes que coincidan', style: theme.textTheme.bodyMedium),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final msg = filtered[index];
                        return _MessageCard(
                          message: msg,
                          onTap: () {
                            setState(() {
                              msg.unread = false;
                            });
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                              builder: (_) => Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(
                                    children: [
                                      CircleAvatar(child: Text(_initials(msg.sender))),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(msg.sender, style: theme.textTheme.titleMedium)),
                                      Text(_formatTime(msg.time), style: theme.textTheme.bodySmall),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(msg.text, style: theme.textTheme.bodyLarge),
                                  const SizedBox(height: 12),
                                ]),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar mensajes',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: theme.colorScheme.onPrimary.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      onChanged: (v) => setState(() => _search = v),
    );
  }

  static String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  static String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _Message {
  String sender;
  String text;
  DateTime time;
  bool unread;

  _Message({required this.sender, required this.text, required this.time, this.unread = false});
}

class _MessageCard extends StatelessWidget {
  final _Message message;
  final VoidCallback? onTap;

  const _MessageCard({required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(radius: 26, child: Text(_initials(message.sender))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(message.sender, style: theme.textTheme.titleMedium)),
                    Text(_formatTime(message.time), style: theme.textTheme.bodySmall),
                  ]),
                  const SizedBox(height: 6),
                  Text(message.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                ]),
              ),
              const SizedBox(width: 8),
              if (message.unread)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Nuevo', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
