# ASSella Nix Flake

A Nix flake that packages [ASSella](https://github.com/niwia/ASSella), an ACCELA fork.

## Quick Start

## Requirements

Make sure flakes are enabled in your Nix configuration:

```conf
experimental-features = nix-command flakes
```

### Using with Flakes

Add this flake as an input to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    assella = {
      url = "github:UltimatePlayer97/ASSella-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

Then install it in your system configuration:

```nix
environment.systemPackages = [
  inputs.assella.packages.${pkgs.system}.default
];
```

### Home Manager

For Home Manager users:

```nix
home.packages = [
  inputs.assella.packages.${pkgs.system}.default
];
```

### Direct Installation

You can also install ASSella directly without adding it to your flake inputs:

```bash
# Install to user profile
nix profile install github:UltimatePlayer97/ASSella-nix#assella

# Or run directly
nix run github:UltimatePlayer97/ASSella-nix#assella
```

### Temporary Shell

```bash
nix shell github:UltimatePlayer97/ASSella-nix#assella
assella
```

## Features

- Packaged as a Nix flake
- Desktop entry and icon included
- Supports `x-scheme-handler/accela`
- Linux support for:
  - `x86_64-linux`
  - `aarch64-linux`

## Development

### Building Locally

```bash
# Build the package
nix build .#assella

# Run without installing
nix run .#assella
```
