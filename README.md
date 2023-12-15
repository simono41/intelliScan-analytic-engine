# intelliScan Analytic Engine

intelliScan Analytic Engine ist eine SwiftUI-Anwendung, die die Texterkennungsfunktionen von Apple Vision verwendet, um Text live von der Kamera aufzunehmen. Die Anwendung kann Texte analysieren, nach einem bestimmten Regex-Muster suchen und bei Übereinstimmung eine Benachrichtigung anzeigen.

## Funktionalitäten

- **Texterkennung**: Die Anwendung verwendet die Vision Framework von Apple, um Text live von der Kamera zu erkennen.
  
- **Regex-Matching**: Es ist möglich, die erkannten Texte auf Übereinstimmung mit einem benutzerdefinierten Regex-Muster zu prüfen.

- **Benachrichtigung bei Übereinstimmung**: Wenn ein Text mit dem Regex-Muster übereinstimmt, wird eine Benachrichtigung angezeigt.

- **Rechteckzeichnung**: Die Position des erkannten Textes wird auf dem Bildschirm mit Rechtecken markiert.

## Systemanforderungen

- iOS 14.0 oder höher
- Swift 5.0 oder höher
- Xcode 12.0 oder höher

## Installation

1. Klonen Sie das Repository.
2. Öffnen Sie das Projekt in Xcode.
3. Wählen Sie Ihr Zielgerät und starten Sie die Anwendung.

## Anpassungen

- **Regex-Muster ändern**: Du kannst das Regex-Muster in der `checkForRegexMatch`-Funktion in `CameraView` anpassen.
- **Benachrichtigung anpassen**: Du kannst den Benachrichtigungstext und das Verhalten in der `isShowingPopup`-Variable und dem dazugehörigen `Alert`-Block in `ContentView` anpassen.

## Lizenz

Dieses Projekt ist unter der [MIT-Lizenz](LICENSE) lizenziert - siehe die [LICENSE](LICENSE)-Datei für Details.
