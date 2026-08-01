# Font configuration for the system, including general-purpose and developer fonts.
{pkgs, ...}: {
  fonts.fontDir.enable = true;
  fonts.packages = with pkgs; [
    # Massive Unicode coverage
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji

    # Developer fonts
    nerd-fonts.meslo-lg
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code

    # Nice general-purpose fonts
    liberation_ttf
    dejavu_fonts

    # Microsoft-compatible fonts
    corefonts

    # Optional: nicer UI/document fonts
    inter
    source-sans
    source-serif

    # Fancy fonts
    font-awesome
  ];
}
