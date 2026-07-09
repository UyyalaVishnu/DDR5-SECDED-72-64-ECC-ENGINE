# DDR5 ECC Engine

A high-performance VLSI implementation of a SECDED (Single Error Correction, Double Error Detection) Error Correcting Code (ECC) engine for DDR5 memory subsystems.

## Overview

This project implements a fully synthesized and physically verified on-die ECC engine in 45nm CMOS technology. The design follows the JEDEC JESD79-5B specification for DDR5 memory systems and provides robust error protection for 64-bit data with 8-bit SECDED encoding, resulting in a 72-bit codeword.

### Key Features

- **SECDED (72,64) Error Correction**: Corrects single-bit errors and detects double-bit errors
- **JEDEC JESD79-5B Compliant**: Fully aligned with DDR5 memory specification standards
- **2-Stage Pipeline Architecture**:
  - Stage 1: Fully unrolled combinational parity computation
  - Stage 2: Syndrome calculation and error correction logic
- **High Frequency**: 500 MHz target frequency in 45nm technology (2ns clock period)
- **Comprehensive Verification**: SystemVerilog assertions and extensive testbenches
- **Production Ready**: Complete sign-off with DRC, LVS, and timing verification

## Project Structure

```
DDR5_ECC_ENGINE/
├── RTL/                      # RTL Design
│   ├── DDR5.v               # Main ECC engine Verilog module
│   └── DDR5_TB.v            # Comprehensive testbench
├── synthesis/               # Synthesis Results
│   └── reports/             # Area, power, timing reports
├── implementation/          # Physical Implementation
│   └── reports/             # Place & Route analysis
├── sign off/                # Design Sign-Off
│   ├── reports/             # Final verification reports
│   ├── ecc_engine_final.v   # Final netlist
│   ├── ecc_engine.gds       # GDS II layout file
│   └── top_netlist.v        # Top-level netlist
├── savedDesigns/            # Design checkpoints
├── CONSTRAINTS/             # Timing, power, and process constraints
└── tb/                      # Additional testbenches
```

## Design Specifications

| Parameter | Value | Notes |
|-----------|-------|-------|
| Data Width | 64 bits | Input data for encoding |
| ECC Width | 8 bits | Check bits for SECDED |
| Codeword Width | 72 bits | Total encoded data |
| Technology | 45nm | CMOS |
| Target Frequency | 500 MHz | 2ns period |
| Pipeline Stages | 2 | Latency = 2 cycles |
| Standard Cells | 2,119 | Post-implementation instance count |
| Error Capability | SECDED | Single Error Correct, Double Error Detect |

## Functional Description

### Encode Path (Write)
When `op_encode = 1`, the engine generates an 8-bit parity/check word from 64-bit input data:
- Computes 8 independent parity bits using fully unrolled XOR trees
- Produces 72-bit codeword: [data[63:0] | parity[7:0]]
- Optimized for minimal latency and power consumption

### Decode Path (Read)
When `op_decode = 1`, the engine decodes and corrects the 72-bit codeword:
- Calculates syndrome bits from received codeword
- Detects error position (if any) using syndrome to error index mapping
- Corrects single-bit errors transparently
- Flags uncorrectable (double-bit) errors for system-level handling

### Features
- One-hot operation select (`op_encode`, `op_decode`)
- Valid signal handshaking (`valid_in`, `valid_out`)
- Asynchronous reset (`rst_n`)
- Fully synchronous operation with single clock domain

## Implementation Results

### Post-Synthesis Metrics
- **Logic Depth**: Optimized for high-frequency operation
- **Area Footprint**: Minimal routing overhead

### Post-Implementation Metrics
- **Total Area**: Derived from 2,119 standard cells in 45nm technology
- **Power Consumption**: Reported in detailed power analysis reports
- **Timing**: Setup/Hold timing closed across all corners
- **Routing**: Metal-6 layer utilized for optimal performance

### Verification Coverage
- **Setup Timing**: ✓ Closed (all corners)
- **Hold Timing**: ✓ Closed (all corners)
- **Design Rule Check (DRC)**: ✓ No violations
- **Layout vs. Schematic (LVS)**: ✓ Verified

## Testbenches

The project includes comprehensive SystemVerilog testbenches covering:

| Test Case | Description |
|-----------|-------------|
| TC1 | Encode/Decode with no errors |
| TC2 | Single-bit error injection and correction |
| TC3 | Double-bit error detection |
| TC4 | All-zeros data edge case |
| TC5 | All-ones data edge case |

### Running Simulations
```bash
# Compile and simulate (using your simulator, e.g., VCS, ModelSim, etc.)
# Example for VCS:
vcs -full64 -sverilog RTL/DDR5.v RTL/DDR5_TB.v
./simv
```

## Design Constraints

- **Timing Constraints**: [CONSTRAINTS/top_innovus.default_emulate_constraint_mode.sdc](CONSTRAINTS/top_innovus.default_emulate_constraint_mode.sdc)
- **Process Constraints**: Defined in MMMC (Multi-Mode Multi-Corner) setup
- **Power Constraints**: [CONSTRAINTS/top_innovus.wnm_attrs.tcl](CONSTRAINTS/top_innovus.wnm_attrs.tcl)

## Design Flow

The implementation follows an industry-standard SoC design flow:

1. **RTL Design** → Verilog modules with assertions
2. **Synthesis** → Cadence Genus (45nm library)
3. **Place & Route** → Cadence Innovus
4. **Verification** → 
   - Timing analysis (STA)
   - Power analysis
   - DRC/LVS
5. **Sign-off** → GDS II and final netlist generation

## Files of Interest

- **Main Design**: [RTL/DDR5.v](RTL/DDR5.v) - Core ECC engine implementation
- **Testbench**: [RTL/DDR5_TB.v](RTL/DDR5_TB.v) - Comprehensive test vectors
- **Final Netlist**: [sign off/ecc_engine_final.v](sign%20off/ecc_engine_final.v)
- **GDS Layout**: [sign off/ecc_engine.gds](sign%20off/ecc_engine.gds)
- **Area Report**: [sign off/reports/signoff_area.rpt](sign%20off/reports/signoff_area.rpt)
- **Timing Report**: [sign off/reports/signoff_setup.rpt](sign%20off/reports/signoff_setup.rpt)
- **Power Report**: [sign off/reports/signoff_power.rpt](sign%20off/reports/signoff_power.rpt)

## References

- **JEDEC JESD79-5B**: DDR5 SDRAM Standard (Section 8.3 - On-Die ECC)
- **SECDED Codes**: Bose-Chaudhuri SECDED implementation with Hamming code principles
- **Design Tools**: Cadence Genus (Synthesis) and Innovus (Place & Route)

## Author & Acknowledgments

- **Design Engineer**: VVR
- **Technology**: 45nm CMOS
- **Year**: 2026


## Contributing

For contributions, please:
1. Create a feature branch from `main`
2. Ensure all testbenches pass
3. Update documentation as needed
4. Submit pull request with detailed description

## Support

For questions or issues regarding this design, please refer to the project documentation or contact the design team.
