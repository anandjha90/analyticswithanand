"""
adf_analyzer_v10_patched_runner.py

UPDATED TO USE ULTIMATE EDITION
"""

import sys
import argparse
from pathlib import Path

# Add current directory to path for local imports
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

def apply_functional_patches() -> bool:
    """Apply functional (core logic) patches only.

    Returns True on success, False on failure.
    """
    print("\n" + "=" * 80)
    print(" STEP 1: Applying functional patches")
    print("=" * 80 + "\n")
    try:
        from adf_analyzer_v10_patch import apply_all_patches
        success = apply_all_patches()
        if not success:
            print(" Functional patches failed")
            return False
        print(" ✔ Functional patches applied\n")
        return True
    except ImportError as e:
        print(f" ERROR: Cannot import functional patches: {e}")
        return False


def apply_excel_enhancements() -> bool:
    """Apply Excel beautification / ultimate enhancements.

    Safe to call even if module not present; will degrade gracefully.
    """
    print("\n" + "=" * 80)
    print(" STEP 2: Applying Excel beautification (Ultimate Edition)")
    print("=" * 80 + "\n")
    try:
        from adf_analyzer_v10_excel_enhancements import apply_complete_excel_enhancements
        success = apply_complete_excel_enhancements()
        if not success:
            print(" Excel enhancements failed")
            return False
        print(" ✔ Excel beautification applied\n")
        return True
    except ImportError as e:
        print(f"  Excel enhancements not available: {e}")
        print("  Continuing with basic functional output...\n")
        return True  # Treat as non-fatal


def parse_args(argv: list[str]) -> argparse.Namespace:
    """Parse CLI arguments.

    Flags:
      --skip-functional           Skip functional patching (NOT recommended)
      --skip-excel-enhancements   Skip Excel beautification layer
      --basic                     Shortcut for skipping ALL enhancements
      --output <path>             Optional output directory override (passed through)

    Returns argparse.Namespace with parsed values.
    """
    parser = argparse.ArgumentParser(
        description="Run ADF Analyzer v10 Patched Runner with optional enhancement layers",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("template", help="Path to ADF ARM template JSON file")
    parser.add_argument("--skip-functional", action="store_true", help="Do not apply functional patches")
    parser.add_argument(
        "--skip-excel-enhancements",
        action="store_true",
        help="Do not apply Excel beautification / ultimate enhancements",
    )
    parser.add_argument(
        "--basic",
        action="store_true",
        help="Skip ALL enhancements (equivalent to --skip-functional --skip-excel-enhancements)",
    )
    parser.add_argument(
        "--output",
        type=str,
        default="output",
        help="Output directory (must exist or be creatable)",
    )
    return parser.parse_args(argv)

def main():
    """Main entry point with enhancement toggles."""

    args = parse_args(sys.argv[1:])

    json_file = args.template
    if not Path(json_file).exists():
        print(f" ERROR: File not found: {json_file}")
        sys.exit(1)

    # Resolve combined flags
    skip_functional = args.skip_functional or args.basic
    skip_excel = args.skip_excel_enhancements or args.basic

    print("""
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   🚀 ADF ANALYZER v10.1 - ULTIMATE EDITION Runner                            ║
║                                                                              ║
║   Selected Options:                                                          ║
║     Functional patches: {functional}                                         ║
║     Excel enhancements: {excel}                                              ║
║     Output directory: {outdir}                                               ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
    """.format(
        functional="SKIPPED" if skip_functional else "ENABLED",
        excel="SKIPPED" if skip_excel else "ENABLED",
        outdir=args.output,
    ))

    try:
        # Functional patches
        if not skip_functional:
            if not apply_functional_patches():
                print(" Enhancement application failed (functional layer)")
                sys.exit(1)
        else:
            print("⚠ Skipping functional patch layer – proceeding with base analyzer code")

        # Excel enhancements
        if not skip_excel:
            if not apply_excel_enhancements():
                print(" Excel enhancement layer reported failure; continuing with basic export")
        else:
            print("ℹ Excel beautification skipped by user request")

        # Run analysis
        print("\n Running analysis...")
        from adf_analyzer_v10_complete import UltimateEnterpriseADFAnalyzer

        analyzer = UltimateEnterpriseADFAnalyzer(
            json_file,
            enable_discovery=True,
            log_level=2
        )

        success = analyzer.run()

        if success:
            print("\n" + "=" * 80)
            print("🎉 SUCCESS! ANALYSIS COMPLETE!")
            print("=" * 80)
            print(f"\n📁 Output (Excel): {args.output}/adf_analysis_latest.xlsx")
            if not skip_excel:
                print(" Includes advanced dashboards & beautification layer")
            else:
                print(" Basic workbook generated (beautification disabled)")
            print("=" * 80 + "\n")
        else:
            print(" Analysis failed")
            sys.exit(1)

    except Exception as e:
        print(f"\n FATAL ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()