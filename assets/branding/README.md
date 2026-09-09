# Splitka icon

The receipt is split into three strips for the three roommates. Mint green and
blue follow the existing app palette. The dark background is #101711.

- `splitka-foreground.png`: generated source with transparent alpha; used by the
  dashboard and Android adaptive foreground.
- `splitka-icon.png`: opaque square artwork for Android legacy and iOS icons.
- Platform sizes are generated from the configuration in `pubspec.yaml`.
- Android applies its own adaptive mask. iOS assets have their alpha removed.

Regenerate the platform assets after changing the source files:

```sh
flutter pub get
dart run tool/generate_icons.dart
```

Do not edit the generated platform PNGs independently.

The project wrapper preserves the existing Xcode project settings. Version
0.14.4 of flutter_launcher_icons otherwise changes unrelated ASSETCATALOG
settings when it selects AppIcon. Use the wrapper instead of the package CLI.

## Generation provenance

Created with the built-in image_gen tool, using the imagegen skill (not the API
or CLI fallback). The source PNGs are included in this repository, so building
or regenerating platform sizes does not require an image generation service.

### Original prompt

Use case: logo-brand.
Asset type: production mobile app launcher icon source, square 1024 x 1024 PNG.
Primary request: Design a memorable polished icon for Splitka, a Polish roommate grocery receipt splitting app for three friends. The graphic is one bold mint-green paper receipt, subtly separated into three chunky interlocking vertical portions suggesting sharing; the right-hand portion is a small periwinkle blue accent. Use an elegant simple dark negative-space S-shaped separation if it fits naturally. Clearly recognizable paper receipt silhouette with a few large bottom zigzag teeth and just two short dark receipt lines near the top. No tiny details.
Style: premium contemporary flat geometric brand symbol, crisp clean edges, strong contrast, friendly understated utility. No words, letters, currency symbols, people, photographs, mockups, borders, gradients, textures, shine, lighting effects or shadows.
Palette: main mint green #64D487, small blue #7DA8FF, dark evergreen #101711 for line details.
Composition: centered, upright, compact, the mark occupies approximately the central 62 percent of width and 62 percent of height. Large clean transparent margins. Do not draw an app tile, surrounding square, rounded rectangle or circle. The operating systems provide the outside shape.
Background: genuinely transparent alpha channel around the standalone symbol, not a checkerboard painted into the image.
Output only the single finished icon artwork, not a presentation sheet.

### Background edit prompt

Edit target: the attached Splitka receipt icon. Preserve the exact symbol, its three mint/blue paper strips, positions, scale, silhouette and transparent margins' dimensions. Change only the background: flatten the transparent image onto a completely opaque, perfectly solid dark evergreen #101711 background filling the entire square to every edge. No gradient, no texture, no shadows, no border, no rounded app tile, no mockup, no text. Maintain the square composition. Output the final flat square production mobile launcher icon PNG.
