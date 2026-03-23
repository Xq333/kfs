{ pkgs ? import <nixpkgs> {} }:

let
  # For macOS, we'll use a Linux builder or Docker approach
  # This creates a helper script to use Docker for grub-mkrescue
  grubMkrescueWrapper = pkgs.writeShellScriptBin "grub-mkrescue" ''
    if ! command -v docker &> /dev/null; then
      echo "Error: Docker is required for grub-mkrescue on macOS"
      echo "Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
      exit 1
    fi
    
    # Use x86_64 Debian container with GRUB PC BIOS binaries
    docker run --rm --platform linux/amd64 \
      -v "$(pwd):/workspace" -w /workspace \
      debian:bullseye bash -c "
      set -e
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq > /dev/null 2>&1
      apt-get install -y -qq grub2-common grub-pc-bin xorriso mtools > /dev/null 2>&1
      grub-mkrescue \"\$@\"
    " -- "$@"
  '';
in

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Zig compiler
    zig

    # Build tools
    gnumake

    # GRUB and bootloader tools
    xorriso

    # QEMU for testing
    qemu

    # Other utilities
    coreutils
  ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
    # Native GRUB on Linux
    grub2
    
    # GDB (only on Linux - macOS cross-arch debugging is complex)
    gdb
  ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    # Docker-based GRUB wrapper for macOS
    grubMkrescueWrapper
  ];

  shellHook = ''
    echo "🚀 Kernel development environment loaded!"
    echo "Available tools:"
    echo "  - zig $(zig version)"
    echo "  - make"
    ${if pkgs.stdenv.isLinux then ''
    echo "  - grub-mkrescue (native)"
    '' else ''
    echo "  - grub-mkrescue (via Docker - requires Docker Desktop)"
    ''}
    echo "  - qemu-system-x86_64"
    echo "  - xorriso"
    echo ""
    ${if pkgs.stdenv.isDarwin then ''
    echo "📝 Note: On macOS, grub-mkrescue uses Docker to run GRUB in a Linux container."
    echo "    Make sure Docker Desktop is installed and running."
    echo ""
    '' else ""}
    echo "Run 'make' to build the kernel"
  '';
}
