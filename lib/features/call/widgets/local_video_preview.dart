import 'package:material_ui/material_ui.dart';
import 'package:relay/app/theme/relay_tokens.dart';
import 'package:relay/features/call/widgets/mock_video_surface.dart';

class LocalVideoPreview extends StatelessWidget {
  const LocalVideoPreview({
    super.key,
    this.width = 104,
    this.height,
    this.cameraOff = false,
    this.flipped = false,
    this.onTap,
  });

  final double width;
  final double? height;
  final bool cameraOff;
  final bool flipped;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final resolvedHeight = height ?? (MediaQuery.sizeOf(context).height < 650 ? 112.0 : 148.0);

    return Semantics(
      label: cameraOff
          ? 'Self view camera off'
          : flipped
          ? 'Rear camera preview selected'
          : 'Self view',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: resolvedHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(RelayRadius.md),
            border: Border.all(color: colors.outlineVariant, width: 1.5),
          ),
          child: MockVideoSurface(selfView: true, cameraOff: cameraOff),
        ),
      ),
    );
  }
}
