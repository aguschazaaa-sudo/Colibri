import 'package:fpdart/fpdart.dart';

import 'package:cobrador/domain/failure.dart';
import 'package:cobrador/domain/provider.dart';
import 'package:cobrador/domain/provider_repository.dart';

class UpdateProviderProfileUseCase {
  final ProviderRepository _repository;

  UpdateProviderProfileUseCase(this._repository);

  Future<Either<Failure, Provider>> execute(Provider provider) async {
    if (provider.name.trim().isEmpty) {
      return const Left(
        Failure.validationError(
          'El nombre del profesional no puede estar vacío.',
        ),
      );
    }

    final template = provider.whatsappTemplate ?? '';
    if (template.isNotEmpty) {
      if (!template.contains('{{nombre_paciente}}') ||
          !template.contains('{{monto_total}}')) {
        return const Left(
          Failure.validationError(
            'La plantilla de WhatsApp debe incluir {{nombre_paciente}} y {{monto_total}}.',
          ),
        );
      }
    }

    return _repository.updateProviderProfile(provider);
  }
}
