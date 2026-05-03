import 'package:flutter/material.dart';

class AppTheme {
  // ==========================================
  // PALETTE DE COULEURS
  // ==========================================
  
  // Couleur Primaire (Confiance, Sérieux)
  static const Color primaryBlue = Color(0xFF0E62CC); // Bleu Fintech
  static const Color primaryDark = Color(0xFF0A4A9C);
  
  // Couleurs Sémantiques (Finances)
  static const Color positiveGreen = Color(0xFF10B981); // Entrées d'argent, Prêts donnés
  static const Color negativeRed = Color(0xFFEF4444); // Dettes, Prêts pris, Retards
  static const Color warningOrange = Color(0xFFF59E0B); // En attente, Bientôt dû
  
  // Couleurs de fond et texte
  static const Color backgroundLight = Color(0xFFF5F7FB); // Fond neutre/clair
  static const Color surfaceWhite = Colors.white; // Cartes, Modals
  static const Color textPrimary = Color(0xFF1E293B); // Noir/Gris très foncé
  static const Color textSecondary = Color(0xFF64748B); // Gris moyen

  // ==========================================
  // CONFIGURATION DU THEME
  // ==========================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryBlue,
        onPrimary: Colors.white,
        secondary: primaryDark,
        surface: surfaceWhite,
        background: backgroundLight,
        error: negativeRed,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundLight,
      
      // Typographie moderne (si vous importez GoogleFonts plus tard, ça ira ici)
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),

      // Style de l'AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Style des boutons principaux
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      // Style des cartes (Dashboard, listes)
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      
      // Style des champs de texte
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
