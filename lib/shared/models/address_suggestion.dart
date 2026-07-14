/// Suggestion d'adresse (autocomplétion) — miroir de AddressSuggestionResponse.
class AddressSuggestion {
  final String label; // "Rue Clovis 51100 Reims"
  final String? adresse; // "Rue Clovis"
  final String? ville; // "Reims"
  final String? codePostal; // "51100"

  const AddressSuggestion({
    required this.label,
    this.adresse,
    this.ville,
    this.codePostal,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      label: json['label'] as String? ?? '',
      adresse: json['adresse'] as String?,
      ville: json['ville'] as String?,
      codePostal: json['codePostal'] as String?,
    );
  }
}
