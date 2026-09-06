import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';

/// ВРЕМЕННО для QA — убрать после прогона тестером.
class BookingServicesQaChecklist extends StatelessWidget {
  const BookingServicesQaChecklist({super.key});

  static const _steps = <String>[
    '1. Расписание (⚙): выходные, горизонт, часы работы, часы отмены клиентом — Сохранить',
    '2. Блоки времени + график мастера по дням (в настройках) — проверить, что сохранилось',
    '3. Создать услугу (+): название, emoji, длительность, цена, исполнители — Сохранить',
    '4. Открыть услугу → править поля → Сохранить; список обновился',
    '5. Со своего профиля / поста: записаться как клиент — только свободные слоты',
    '6. Inbox хозяина: подтвердить / клиент пришёл / «Оказана» только вручную',
    '7. Перенос записи (host и client): в шторке только доступные слоты',
    '8. Отмена клиентом в окне часов; поздно — кнопка недоступна / ошибка',
    '9. Аналитика записи (если есть вход): период, цифры без падения',
    '10. Не проверять: отзывы после визита, смену услуги у уже опубликованного поста, язык',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = bookingServiceAccent(colors);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: accent.soft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QA · временно · запись по порядку',
            style: AppTextStyle.base(14, color: colors.textColor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Пройди шаги сверху вниз. После теста — сказать, чтобы блок убрали.',
            style: AppTextStyle.base(12, color: colors.subTextColor, height: 1.35),
          ),
          const SizedBox(height: 10),
          for (final step in _steps) ...[
            Text(
              step,
              style: AppTextStyle.base(13, color: colors.textColor, height: 1.35),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}
