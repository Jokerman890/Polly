import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';

// Provider für aktives Glossar
final activeGlossaryProvider = StateProvider<Map<String, String>>((ref) => {});
// Provider für den Namen des aktiven Glossars
final activeGlossaryNameProvider = StateProvider<String?>((ref) => null);
// Provider für alle verfügbaren Glossare
final availableGlossariesProvider = StateProvider<Map<String, Map<String, String>>>((ref) => {});

class GlossaryControl extends ConsumerStatefulWidget {
  final Function(Map<String, String>, String?) onGlossaryChanged;
  final bool compact;

  const GlossaryControl({
    Key? key,
    required this.onGlossaryChanged,
    this.compact = false,
  }) : super(key: key);

  @override
  ConsumerState<GlossaryControl> createState() => _GlossaryControlState();
}

class _GlossaryControlState extends ConsumerState<GlossaryControl> {
  final StorageService _storageService = StorageService();
  final TextEditingController _sourceTermController = TextEditingController();
  final TextEditingController _targetTermController = TextEditingController();
  final TextEditingController _glossaryNameController = TextEditingController();
  bool _isCreatingNewGlossary = false;
  bool _isShowingGlossaryEditor = false;

  @override
  void initState() {
    super.initState();
    _loadGlossaries();
  }

  Future<void> _loadGlossaries() async {
    try {
      final glossaries = await _storageService.getAllGlossaries();
      ref.read(availableGlossariesProvider.notifier).state = glossaries;
    } catch (e) {
      debugPrint('Fehler beim Laden der Glossare: $e');
    }
  }

  void _addTermToGlossary() {
    if (_sourceTermController.text.isNotEmpty && _targetTermController.text.isNotEmpty) {
      final sourceTerm = _sourceTermController.text.trim();
      final targetTerm = _targetTermController.text.trim();
      
      // Aktives Glossar aktualisieren
      final activeGlossary = Map<String, String>.from(ref.read(activeGlossaryProvider));
      activeGlossary[sourceTerm] = targetTerm;
      ref.read(activeGlossaryProvider.notifier).state = activeGlossary;
      
      // UI-Felder zurücksetzen
      _sourceTermController.clear();
      _targetTermController.clear();
      
      // Callback aufrufen
      widget.onGlossaryChanged(activeGlossary, ref.read(activeGlossaryNameProvider));
    }
  }

  void _removeTermFromGlossary(String term) {
    final activeGlossary = Map<String, String>.from(ref.read(activeGlossaryProvider));
    activeGlossary.remove(term);
    ref.read(activeGlossaryProvider.notifier).state = activeGlossary;
    
    // Callback aufrufen
    widget.onGlossaryChanged(activeGlossary, ref.read(activeGlossaryNameProvider));
  }

  Future<void> _saveCurrentGlossary() async {
    final glossaryName = _glossaryNameController.text.trim();
    
    if (glossaryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte geben Sie einen Namen für das Glossar ein')),
      );
      return;
    }
    
    final activeGlossary = ref.read(activeGlossaryProvider);
    
    if (activeGlossary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Das Glossar ist leer')),
      );
      return;
    }
    
    final success = await _storageService.saveGlossary(activeGlossary, glossaryName);
    
    if (success) {
      ref.read(activeGlossaryNameProvider.notifier).state = glossaryName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Glossar "$glossaryName" gespeichert')),
      );
      
      _isCreatingNewGlossary = false;
      _glossaryNameController.clear();
      await _loadGlossaries();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern des Glossars')),
      );
    }
  }

  void _selectGlossary(String name, Map<String, String> glossary) {
    ref.read(activeGlossaryProvider.notifier).state = Map<String, String>.from(glossary);
    ref.read(activeGlossaryNameProvider.notifier).state = name;
    
    // Callback aufrufen
    widget.onGlossaryChanged(glossary, name);
    
    // Editor schließen
    setState(() {
      _isShowingGlossaryEditor = false;
    });
  }

  Future<void> _deleteGlossary(String name) async {
    final success = await _storageService.deleteGlossary(name);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Glossar "$name" gelöscht')),
      );
      
      // Wenn das aktive Glossar gelöscht wurde, setze es zurück
      if (ref.read(activeGlossaryNameProvider) == name) {
        ref.read(activeGlossaryProvider.notifier).state = {};
        ref.read(activeGlossaryNameProvider.notifier).state = null;
        
        // Callback aufrufen
        widget.onGlossaryChanged({}, null);
      }
      
      await _loadGlossaries();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Löschen des Glossars')),
      );
    }
  }

  void _createNewGlossary() {
    setState(() {
      _isCreatingNewGlossary = true;
      _isShowingGlossaryEditor = true;
    });
    
    ref.read(activeGlossaryProvider.notifier).state = {};
    ref.read(activeGlossaryNameProvider.notifier).state = null;
    
    // Callback aufrufen
    widget.onGlossaryChanged({}, null);
  }

  @override
  void dispose() {
    _sourceTermController.dispose();
    _targetTermController.dispose();
    _glossaryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeGlossary = ref.watch(activeGlossaryProvider);
    final activeGlossaryName = ref.watch(activeGlossaryNameProvider);
    final availableGlossaries = ref.watch(availableGlossariesProvider);

    if (widget.compact) {
      return _buildCompactView(activeGlossaryName, availableGlossaries);
    }

    return _buildFullView(activeGlossary, activeGlossaryName, availableGlossaries);
  }

  Widget _buildCompactView(String? activeGlossaryName, Map<String, Map<String, String>> availableGlossaries) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Glossar',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            value: activeGlossaryName,
            hint: Text('Glossar wählen'),
            items: [
              ...availableGlossaries.keys.map((name) => DropdownMenuItem(
                value: name,
                child: Text(name, overflow: TextOverflow.ellipsis),
              )).toList(),
              if (availableGlossaries.isNotEmpty) DropdownMenuItem(
                value: null,
                child: Text('Kein Glossar'),
              ),
            ],
            onChanged: (String? value) {
              if (value == null) {
                ref.read(activeGlossaryProvider.notifier).state = {};
                ref.read(activeGlossaryNameProvider.notifier).state = null;
                widget.onGlossaryChanged({}, null);
              } else {
                _selectGlossary(value, availableGlossaries[value] ?? {});
              }
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () {
            setState(() {
              _isShowingGlossaryEditor = true;
            });
          },
          tooltip: 'Glossar bearbeiten',
        ),
      ],
    );
  }

  Widget _buildFullView(Map<String, String> activeGlossary, String? activeGlossaryName, Map<String, Map<String, String>> availableGlossaries) {
    if (_isShowingGlossaryEditor) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isCreatingNewGlossary ? 'Neues Glossar erstellen' : 'Glossar bearbeiten',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isShowingGlossaryEditor = false;
                    _isCreatingNewGlossary = false;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Glossar-Name
          if (_isCreatingNewGlossary)
            TextField(
              controller: _glossaryNameController,
              decoration: InputDecoration(
                labelText: 'Glossarname',
                border: OutlineInputBorder(),
                hintText: 'z.B. Technische Terminologie',
              ),
            ),
          
          // Existierende Glossare anzeigen, wenn nicht neu erstellt wird
          if (!_isCreatingNewGlossary)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Glossar wählen',
                border: OutlineInputBorder(),
              ),
              value: activeGlossaryName,
              items: availableGlossaries.keys.map((name) => DropdownMenuItem(
                value: name,
                child: Text(name),
              )).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  _selectGlossary(value, availableGlossaries[value] ?? {});
                }
              },
            ),
          
          SizedBox(height: 16),
          
          // Neue Term-Eingabe
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _sourceTermController,
                  decoration: InputDecoration(
                    labelText: 'Quellbegriff',
                    border: OutlineInputBorder(),
                    hintText: 'z.B. cloud computing',
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _targetTermController,
                  decoration: InputDecoration(
                    labelText: 'Zielbegriff',
                    border: OutlineInputBorder(),
                    hintText: 'z.B. Cloud-Computing',
                  ),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.add_circle),
                onPressed: _addTermToGlossary,
                tooltip: 'Begriff hinzufügen',
                color: Colors.blue,
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Glossar-Inhalt anzeigen
          Text(
            'Glossar-Begriffe:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          
          // Liste der Begriffe mit Lösch-Option
          if (activeGlossary.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Keine Begriffe definiert',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: activeGlossary.length,
                itemBuilder: (context, index) {
                  final term = activeGlossary.keys.elementAt(index);
                  final translation = activeGlossary[term];
                  
                  return ListTile(
                    dense: true,
                    title: Text('$term → $translation'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, size: 18),
                      onPressed: () => _removeTermFromGlossary(term),
                      tooltip: 'Begriff entfernen',
                    ),
                  );
                },
              ),
            ),
          
          SizedBox(height: 16),
          
          // Aktionen
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!_isCreatingNewGlossary && activeGlossaryName != null)
                TextButton.icon(
                  onPressed: () => _deleteGlossary(activeGlossaryName),
                  icon: Icon(Icons.delete),
                  label: Text('Löschen'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              
              SizedBox(width: 8),
              
              if (_isCreatingNewGlossary || activeGlossaryName != null)
                ElevatedButton.icon(
                  onPressed: _saveCurrentGlossary,
                  icon: Icon(Icons.save),
                  label: Text('Speichern'),
                ),
              
              if (!_isCreatingNewGlossary)
                TextButton.icon(
                  onPressed: _createNewGlossary,
                  icon: Icon(Icons.add),
                  label: Text('Neues Glossar'),
                ),
            ],
          ),
        ],
      );
    } else {
      // Kompakte Ansicht mit Glossarauswahl
      return Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Glossar',
                border: OutlineInputBorder(),
              ),
              value: activeGlossaryName,
              hint: Text('Glossar wählen'),
              items: [
                ...availableGlossaries.keys.map((name) => DropdownMenuItem(
                  value: name,
                  child: Text(name),
                )).toList(),
                if (availableGlossaries.isNotEmpty) DropdownMenuItem(
                  value: null,
                  child: Text('Kein Glossar'),
                ),
              ],
              onChanged: (String? value) {
                if (value == null) {
                  ref.read(activeGlossaryProvider.notifier).state = {};
                  ref.read(activeGlossaryNameProvider.notifier).state = null;
                  widget.onGlossaryChanged({}, null);
                } else {
                  _selectGlossary(value, availableGlossaries[value] ?? {});
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isShowingGlossaryEditor = true;
                _isCreatingNewGlossary = false;
              });
            },
            tooltip: 'Glossar bearbeiten',
          ),
        ],
      );
    }
  }
} 