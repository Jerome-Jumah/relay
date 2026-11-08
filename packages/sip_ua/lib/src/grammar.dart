import 'grammar_parser.dart';
import 'logger.dart';

class Grammar {
  static dynamic parse(String input, String startRule) {
    GrammarParser parser = GrammarParser('');
    dynamic result = parser.parse(input, startRule);
    if (!parser.success) {
      result = parser.parse(input, startRule);
      // Parser context may contain authentication headers or SDP credentials.
      logger.w('SIP grammar parse failed');
      throw FormatException();
    }
    return result;
  }
}
