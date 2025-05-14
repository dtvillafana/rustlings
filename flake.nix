{
    description = "Rust development environment with common crates";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        rust-overlay = {
            url = "github:oxalica/rust-overlay";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        flake-utils.url = "github:numtide/flake-utils";
    };

    outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
        flake-utils.lib.eachDefaultSystem (system:
            let
                overlays = [ (import rust-overlay) ];
                pkgs = import nixpkgs {
                    inherit system overlays;
                };

                # Select the rust toolchain you want
                rustVersion = pkgs.rust-bin.stable.latest.default;

                # Common Rust dependencies
                rustDeps = with pkgs; [
                    # Build tools
                    pkg-config
                    cmake

                    # Libraries commonly needed for Rust crates
                    openssl.dev
                    openssl.out

                    # For sqlite support
                    sqlite

                    # For system libs
                    glib
                    cairo
                    pango
                    atk
                    gdk-pixbuf
                    gtk3

                    # For clippy and other tools
                    rustfmt
                    clippy
                ];

                # System dependencies for common crates
                systemLibs = with pkgs; [
                    # For network-related crates
                    curl

                    # For image processing
                    libpng
                    libjpeg

                    # For crypto
                    gpgme
                ];
            in
                {
                devShells.default = pkgs.mkShell {
                    buildInputs = [
                        # Rust toolchain with cargo, rustc, etc.
                        (rustVersion.override {
                            extensions = [
                                "rust-src"       # For rust-analyzer
                                "rust-analyzer"  # LSP server
                                "clippy"         # Linting
                                "rustfmt"        # Code formatting
                            ];
                        })
                    ] ++ rustDeps ++ systemLibs;

                    # Set environment variables
                    shellHook = ''
            export RUST_BACKTRACE=1
            export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig"
            export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath systemLibs}"

            # Welcome message
            echo "🦀 Rust development environment loaded!"
            echo "Rust toolchain: $(rustc --version)"
            echo "Cargo: $(cargo --version)"
            echo "Clippy: $(cargo clippy --version)"
            echo "Rustfmt: $(cargo fmt --version)"
            echo ""
            echo "Common crates available:"
            echo "- serde (serialization/deserialization)"
            echo "- tokio (async runtime)"
            echo "- reqwest (HTTP client)"
            echo "- rusqlite (SQLite)"
            echo "- rand (random number generation)"
            echo "- clap (command line argument parsing)"
            echo ""
            echo "Add them to your Cargo.toml as needed!"
            '';
                };

                # Example package (optional)
                packages.default = pkgs.rustPlatform.buildRustPackage {
                    pname = "rust-app";
                    version = "0.1.0";
                    src = ./.;
                    cargoLock = {
                        lockFile = ./Cargo.lock;
                    };
                    buildInputs = rustDeps ++ systemLibs;
                };
            }
        );
}
