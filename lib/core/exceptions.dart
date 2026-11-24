/// Erro de regra de negócio (mensagem pensada para ser mostrada ao usuário).
class RegraNegocioException implements Exception {
  const RegraNegocioException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Converte qualquer erro em texto amigável para exibir em SnackBar/diálogo.
String mensagemErro(Object erro) {
  if (erro is RegraNegocioException) {
    return erro.message;
  }
  return 'Ocorreu um erro: $erro';
}
