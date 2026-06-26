//==============================================================================
// Module      : ecc_engine
// Project     : DDR5 Memory Subsystem SoC
// Description : SECDED (72,64) On-Die ECC Engine
//               - Fully unrolled combinational parity (JESD79-5B aligned)
//               - 2-stage pipeline: Stage1=parity, Stage2=syndrome+correct
//               - SVA protocol assertions
//               - Parameterized for easy width extension
// Author      : VVR | IIITDM Kurnool Internship
// Spec Ref    : JEDEC JESD79-5B Section 8.3 (On-Die ECC)
// Node        : 45nm  Target Freq : 500 MHz (2ns period)
//==============================================================================
`default_nettype none
`timescale 1ns/1ps

module ecc_engine #(
    parameter DATA_WIDTH = 64,   // Must be 64 for SECDED(72,64)
    parameter ECC_WIDTH  = 8     // 8 check bits → 72-bit codeword
) (
    input  wire                  clk,
    input  wire                  rst_n,

    // Operation select — one-hot, mutually exclusive
    input  wire                  op_encode,      // 1 = encode (write path)
    input  wire                  op_decode,      // 1 = decode (read path)
    input  wire                  valid_in,

    // Encode path
    input  wire [DATA_WIDTH-1:0] data_in,        // 64-bit raw write data
    output reg  [71:0]           codeword_out,   // 72-bit to PHY

    // Decode path
    input  wire [71:0]           codeword_in,    // 72-bit from PHY
    output reg  [DATA_WIDTH-1:0] data_out,       // Corrected 64-bit data
    output reg                   ecc_corrected,  // Single-bit corrected
    output reg                   ecc_uncorrectable, // Double-bit detected

    output reg                   valid_out
);

//------------------------------------------------------------------------------
// SECDED (72,64) Parity Generation — Fully Unrolled
// Parity matrix derived from JEDEC DDR5 spec JESD79-5B
// Layout: codeword[71:8] = data[63:0], codeword[7:0] = parity[7:0]
//------------------------------------------------------------------------------

// --- Combinational parity computation (Stage 1 input) ---
// =========================================================
// Balanced-tree parity generation (encode side)
// =========================================================
wire [7:0] gen_parity;
wire gp0_l0_0 = data_in[0] ^ data_in[1];
wire gp0_l0_1 = data_in[3] ^ data_in[4];
wire gp0_l0_2 = data_in[6] ^ data_in[8];
wire gp0_l0_3 = data_in[10] ^ data_in[11];
wire gp0_l0_4 = data_in[13] ^ data_in[15];
wire gp0_l0_5 = data_in[17] ^ data_in[19];
wire gp0_l0_6 = data_in[21] ^ data_in[23];
wire gp0_l0_7 = data_in[25] ^ data_in[26];
wire gp0_l0_8 = data_in[28] ^ data_in[30];
wire gp0_l0_9 = data_in[32] ^ data_in[34];
wire gp0_l0_10 = data_in[36] ^ data_in[38];
wire gp0_l0_11 = data_in[40] ^ data_in[42];
wire gp0_l0_12 = data_in[44] ^ data_in[46];
wire gp0_l0_13 = data_in[48] ^ data_in[50];
wire gp0_l0_14 = data_in[52] ^ data_in[54];
wire gp0_l0_15 = data_in[56] ^ data_in[57];
wire gp0_l0_16 = data_in[59] ^ data_in[61];
wire gp0_l1_0 = gp0_l0_0 ^ gp0_l0_1;
wire gp0_l1_1 = gp0_l0_2 ^ gp0_l0_3;
wire gp0_l1_2 = gp0_l0_4 ^ gp0_l0_5;
wire gp0_l1_3 = gp0_l0_6 ^ gp0_l0_7;
wire gp0_l1_4 = gp0_l0_8 ^ gp0_l0_9;
wire gp0_l1_5 = gp0_l0_10 ^ gp0_l0_11;
wire gp0_l1_6 = gp0_l0_12 ^ gp0_l0_13;
wire gp0_l1_7 = gp0_l0_14 ^ gp0_l0_15;
wire gp0_l1_8 = gp0_l0_16 ^ data_in[63];
wire gp0_l2_0 = gp0_l1_0 ^ gp0_l1_1;
wire gp0_l2_1 = gp0_l1_2 ^ gp0_l1_3;
wire gp0_l2_2 = gp0_l1_4 ^ gp0_l1_5;
wire gp0_l2_3 = gp0_l1_6 ^ gp0_l1_7;
wire gp0_l3_0 = gp0_l2_0 ^ gp0_l2_1;
wire gp0_l3_1 = gp0_l2_2 ^ gp0_l2_3;
wire gp0_l4_0 = gp0_l3_0 ^ gp0_l3_1;
wire gp0_l5_0 = gp0_l4_0 ^ gp0_l1_8;
assign gen_parity[0] = gp0_l5_0;

wire gp1_l0_0 = data_in[0] ^ data_in[2];
wire gp1_l0_1 = data_in[3] ^ data_in[5];
wire gp1_l0_2 = data_in[6] ^ data_in[9];
wire gp1_l0_3 = data_in[10] ^ data_in[12];
wire gp1_l0_4 = data_in[13] ^ data_in[16];
wire gp1_l0_5 = data_in[17] ^ data_in[20];
wire gp1_l0_6 = data_in[21] ^ data_in[24];
wire gp1_l0_7 = data_in[25] ^ data_in[27];
wire gp1_l0_8 = data_in[28] ^ data_in[31];
wire gp1_l0_9 = data_in[32] ^ data_in[35];
wire gp1_l0_10 = data_in[36] ^ data_in[39];
wire gp1_l0_11 = data_in[40] ^ data_in[43];
wire gp1_l0_12 = data_in[44] ^ data_in[47];
wire gp1_l0_13 = data_in[48] ^ data_in[51];
wire gp1_l0_14 = data_in[52] ^ data_in[55];
wire gp1_l0_15 = data_in[56] ^ data_in[58];
wire gp1_l0_16 = data_in[59] ^ data_in[62];
wire gp1_l1_0 = gp1_l0_0 ^ gp1_l0_1;
wire gp1_l1_1 = gp1_l0_2 ^ gp1_l0_3;
wire gp1_l1_2 = gp1_l0_4 ^ gp1_l0_5;
wire gp1_l1_3 = gp1_l0_6 ^ gp1_l0_7;
wire gp1_l1_4 = gp1_l0_8 ^ gp1_l0_9;
wire gp1_l1_5 = gp1_l0_10 ^ gp1_l0_11;
wire gp1_l1_6 = gp1_l0_12 ^ gp1_l0_13;
wire gp1_l1_7 = gp1_l0_14 ^ gp1_l0_15;
wire gp1_l1_8 = gp1_l0_16 ^ data_in[63];
wire gp1_l2_0 = gp1_l1_0 ^ gp1_l1_1;
wire gp1_l2_1 = gp1_l1_2 ^ gp1_l1_3;
wire gp1_l2_2 = gp1_l1_4 ^ gp1_l1_5;
wire gp1_l2_3 = gp1_l1_6 ^ gp1_l1_7;
wire gp1_l3_0 = gp1_l2_0 ^ gp1_l2_1;
wire gp1_l3_1 = gp1_l2_2 ^ gp1_l2_3;
wire gp1_l4_0 = gp1_l3_0 ^ gp1_l3_1;
wire gp1_l5_0 = gp1_l4_0 ^ gp1_l1_8;
assign gen_parity[1] = gp1_l5_0;

wire gp2_l0_0 = data_in[1] ^ data_in[2];
wire gp2_l0_1 = data_in[3] ^ data_in[7];
wire gp2_l0_2 = data_in[8] ^ data_in[9];
wire gp2_l0_3 = data_in[10] ^ data_in[14];
wire gp2_l0_4 = data_in[15] ^ data_in[16];
wire gp2_l0_5 = data_in[17] ^ data_in[22];
wire gp2_l0_6 = data_in[23] ^ data_in[24];
wire gp2_l0_7 = data_in[25] ^ data_in[29];
wire gp2_l0_8 = data_in[30] ^ data_in[31];
wire gp2_l0_9 = data_in[32] ^ data_in[37];
wire gp2_l0_10 = data_in[38] ^ data_in[39];
wire gp2_l0_11 = data_in[40] ^ data_in[45];
wire gp2_l0_12 = data_in[46] ^ data_in[47];
wire gp2_l0_13 = data_in[48] ^ data_in[53];
wire gp2_l0_14 = data_in[54] ^ data_in[55];
wire gp2_l0_15 = data_in[56] ^ data_in[60];
wire gp2_l0_16 = data_in[61] ^ data_in[62];
wire gp2_l1_0 = gp2_l0_0 ^ gp2_l0_1;
wire gp2_l1_1 = gp2_l0_2 ^ gp2_l0_3;
wire gp2_l1_2 = gp2_l0_4 ^ gp2_l0_5;
wire gp2_l1_3 = gp2_l0_6 ^ gp2_l0_7;
wire gp2_l1_4 = gp2_l0_8 ^ gp2_l0_9;
wire gp2_l1_5 = gp2_l0_10 ^ gp2_l0_11;
wire gp2_l1_6 = gp2_l0_12 ^ gp2_l0_13;
wire gp2_l1_7 = gp2_l0_14 ^ gp2_l0_15;
wire gp2_l1_8 = gp2_l0_16 ^ data_in[63];
wire gp2_l2_0 = gp2_l1_0 ^ gp2_l1_1;
wire gp2_l2_1 = gp2_l1_2 ^ gp2_l1_3;
wire gp2_l2_2 = gp2_l1_4 ^ gp2_l1_5;
wire gp2_l2_3 = gp2_l1_6 ^ gp2_l1_7;
wire gp2_l3_0 = gp2_l2_0 ^ gp2_l2_1;
wire gp2_l3_1 = gp2_l2_2 ^ gp2_l2_3;
wire gp2_l4_0 = gp2_l3_0 ^ gp2_l3_1;
wire gp2_l5_0 = gp2_l4_0 ^ gp2_l1_8;
assign gen_parity[2] = gp2_l5_0;

wire gp3_l0_0 = data_in[4] ^ data_in[5];
wire gp3_l0_1 = data_in[6] ^ data_in[7];
wire gp3_l0_2 = data_in[8] ^ data_in[9];
wire gp3_l0_3 = data_in[10] ^ data_in[18];
wire gp3_l0_4 = data_in[19] ^ data_in[20];
wire gp3_l0_5 = data_in[21] ^ data_in[22];
wire gp3_l0_6 = data_in[23] ^ data_in[24];
wire gp3_l0_7 = data_in[25] ^ data_in[33];
wire gp3_l0_8 = data_in[34] ^ data_in[35];
wire gp3_l0_9 = data_in[36] ^ data_in[37];
wire gp3_l0_10 = data_in[38] ^ data_in[39];
wire gp3_l0_11 = data_in[40] ^ data_in[49];
wire gp3_l0_12 = data_in[50] ^ data_in[51];
wire gp3_l0_13 = data_in[52] ^ data_in[53];
wire gp3_l0_14 = data_in[54] ^ data_in[55];
wire gp3_l1_0 = gp3_l0_0 ^ gp3_l0_1;
wire gp3_l1_1 = gp3_l0_2 ^ gp3_l0_3;
wire gp3_l1_2 = gp3_l0_4 ^ gp3_l0_5;
wire gp3_l1_3 = gp3_l0_6 ^ gp3_l0_7;
wire gp3_l1_4 = gp3_l0_8 ^ gp3_l0_9;
wire gp3_l1_5 = gp3_l0_10 ^ gp3_l0_11;
wire gp3_l1_6 = gp3_l0_12 ^ gp3_l0_13;
wire gp3_l1_7 = gp3_l0_14 ^ data_in[56];
wire gp3_l2_0 = gp3_l1_0 ^ gp3_l1_1;
wire gp3_l2_1 = gp3_l1_2 ^ gp3_l1_3;
wire gp3_l2_2 = gp3_l1_4 ^ gp3_l1_5;
wire gp3_l2_3 = gp3_l1_6 ^ gp3_l1_7;
wire gp3_l3_0 = gp3_l2_0 ^ gp3_l2_1;
wire gp3_l3_1 = gp3_l2_2 ^ gp3_l2_3;
wire gp3_l4_0 = gp3_l3_0 ^ gp3_l3_1;
assign gen_parity[3] = gp3_l4_0;

wire gp4_l0_0 = data_in[11] ^ data_in[12];
wire gp4_l0_1 = data_in[13] ^ data_in[14];
wire gp4_l0_2 = data_in[15] ^ data_in[16];
wire gp4_l0_3 = data_in[17] ^ data_in[18];
wire gp4_l0_4 = data_in[19] ^ data_in[20];
wire gp4_l0_5 = data_in[21] ^ data_in[22];
wire gp4_l0_6 = data_in[23] ^ data_in[24];
wire gp4_l0_7 = data_in[25] ^ data_in[41];
wire gp4_l0_8 = data_in[42] ^ data_in[43];
wire gp4_l0_9 = data_in[44] ^ data_in[45];
wire gp4_l0_10 = data_in[46] ^ data_in[47];
wire gp4_l0_11 = data_in[48] ^ data_in[49];
wire gp4_l0_12 = data_in[50] ^ data_in[51];
wire gp4_l0_13 = data_in[52] ^ data_in[53];
wire gp4_l0_14 = data_in[54] ^ data_in[55];
wire gp4_l1_0 = gp4_l0_0 ^ gp4_l0_1;
wire gp4_l1_1 = gp4_l0_2 ^ gp4_l0_3;
wire gp4_l1_2 = gp4_l0_4 ^ gp4_l0_5;
wire gp4_l1_3 = gp4_l0_6 ^ gp4_l0_7;
wire gp4_l1_4 = gp4_l0_8 ^ gp4_l0_9;
wire gp4_l1_5 = gp4_l0_10 ^ gp4_l0_11;
wire gp4_l1_6 = gp4_l0_12 ^ gp4_l0_13;
wire gp4_l1_7 = gp4_l0_14 ^ data_in[56];
wire gp4_l2_0 = gp4_l1_0 ^ gp4_l1_1;
wire gp4_l2_1 = gp4_l1_2 ^ gp4_l1_3;
wire gp4_l2_2 = gp4_l1_4 ^ gp4_l1_5;
wire gp4_l2_3 = gp4_l1_6 ^ gp4_l1_7;
wire gp4_l3_0 = gp4_l2_0 ^ gp4_l2_1;
wire gp4_l3_1 = gp4_l2_2 ^ gp4_l2_3;
wire gp4_l4_0 = gp4_l3_0 ^ gp4_l3_1;
assign gen_parity[4] = gp4_l4_0;

wire gp5_l0_0 = data_in[26] ^ data_in[27];
wire gp5_l0_1 = data_in[28] ^ data_in[29];
wire gp5_l0_2 = data_in[30] ^ data_in[31];
wire gp5_l0_3 = data_in[32] ^ data_in[33];
wire gp5_l0_4 = data_in[34] ^ data_in[35];
wire gp5_l0_5 = data_in[36] ^ data_in[37];
wire gp5_l0_6 = data_in[38] ^ data_in[39];
wire gp5_l0_7 = data_in[40] ^ data_in[41];
wire gp5_l0_8 = data_in[42] ^ data_in[43];
wire gp5_l0_9 = data_in[44] ^ data_in[45];
wire gp5_l0_10 = data_in[46] ^ data_in[47];
wire gp5_l0_11 = data_in[48] ^ data_in[49];
wire gp5_l0_12 = data_in[50] ^ data_in[51];
wire gp5_l0_13 = data_in[52] ^ data_in[53];
wire gp5_l0_14 = data_in[54] ^ data_in[55];
wire gp5_l1_0 = gp5_l0_0 ^ gp5_l0_1;
wire gp5_l1_1 = gp5_l0_2 ^ gp5_l0_3;
wire gp5_l1_2 = gp5_l0_4 ^ gp5_l0_5;
wire gp5_l1_3 = gp5_l0_6 ^ gp5_l0_7;
wire gp5_l1_4 = gp5_l0_8 ^ gp5_l0_9;
wire gp5_l1_5 = gp5_l0_10 ^ gp5_l0_11;
wire gp5_l1_6 = gp5_l0_12 ^ gp5_l0_13;
wire gp5_l1_7 = gp5_l0_14 ^ data_in[56];
wire gp5_l2_0 = gp5_l1_0 ^ gp5_l1_1;
wire gp5_l2_1 = gp5_l1_2 ^ gp5_l1_3;
wire gp5_l2_2 = gp5_l1_4 ^ gp5_l1_5;
wire gp5_l2_3 = gp5_l1_6 ^ gp5_l1_7;
wire gp5_l3_0 = gp5_l2_0 ^ gp5_l2_1;
wire gp5_l3_1 = gp5_l2_2 ^ gp5_l2_3;
wire gp5_l4_0 = gp5_l3_0 ^ gp5_l3_1;
assign gen_parity[5] = gp5_l4_0;

wire gp6_l0_0 = data_in[57] ^ data_in[58];
wire gp6_l0_1 = data_in[59] ^ data_in[60];
wire gp6_l0_2 = data_in[61] ^ data_in[62];
wire gp6_l1_0 = gp6_l0_0 ^ gp6_l0_1;
wire gp6_l1_1 = gp6_l0_2 ^ data_in[63];
wire gp6_l2_0 = gp6_l1_0 ^ gp6_l1_1;
assign gen_parity[6] = gp6_l2_0;

wire gp7_l0_0 = data_in[0] ^ data_in[1];
wire gp7_l0_1 = data_in[2] ^ data_in[3];
wire gp7_l0_2 = data_in[4] ^ data_in[5];
wire gp7_l0_3 = data_in[6] ^ data_in[7];
wire gp7_l0_4 = data_in[8] ^ data_in[9];
wire gp7_l0_5 = data_in[10] ^ data_in[11];
wire gp7_l0_6 = data_in[12] ^ data_in[13];
wire gp7_l0_7 = data_in[14] ^ data_in[15];
wire gp7_l0_8 = data_in[16] ^ data_in[17];
wire gp7_l0_9 = data_in[18] ^ data_in[19];
wire gp7_l0_10 = data_in[20] ^ data_in[21];
wire gp7_l0_11 = data_in[22] ^ data_in[23];
wire gp7_l0_12 = data_in[24] ^ data_in[25];
wire gp7_l0_13 = data_in[26] ^ data_in[27];
wire gp7_l0_14 = data_in[28] ^ data_in[29];
wire gp7_l0_15 = data_in[30] ^ data_in[31];
wire gp7_l0_16 = data_in[32] ^ data_in[33];
wire gp7_l0_17 = data_in[34] ^ data_in[35];
wire gp7_l0_18 = data_in[36] ^ data_in[37];
wire gp7_l0_19 = data_in[38] ^ data_in[39];
wire gp7_l0_20 = data_in[40] ^ data_in[41];
wire gp7_l0_21 = data_in[42] ^ data_in[43];
wire gp7_l0_22 = data_in[44] ^ data_in[45];
wire gp7_l0_23 = data_in[46] ^ data_in[47];
wire gp7_l0_24 = data_in[48] ^ data_in[49];
wire gp7_l0_25 = data_in[50] ^ data_in[51];
wire gp7_l0_26 = data_in[52] ^ data_in[53];
wire gp7_l0_27 = data_in[54] ^ data_in[55];
wire gp7_l0_28 = data_in[56] ^ data_in[57];
wire gp7_l0_29 = data_in[58] ^ data_in[59];
wire gp7_l0_30 = data_in[60] ^ data_in[61];
wire gp7_l0_31 = data_in[62] ^ data_in[63];
wire gp7_l0_32 = gen_parity[0] ^ gen_parity[1];
wire gp7_l0_33 = gen_parity[2] ^ gen_parity[3];
wire gp7_l0_34 = gen_parity[4] ^ gen_parity[5];
wire gp7_l1_0 = gp7_l0_0 ^ gp7_l0_1;
wire gp7_l1_1 = gp7_l0_2 ^ gp7_l0_3;
wire gp7_l1_2 = gp7_l0_4 ^ gp7_l0_5;
wire gp7_l1_3 = gp7_l0_6 ^ gp7_l0_7;
wire gp7_l1_4 = gp7_l0_8 ^ gp7_l0_9;
wire gp7_l1_5 = gp7_l0_10 ^ gp7_l0_11;
wire gp7_l1_6 = gp7_l0_12 ^ gp7_l0_13;
wire gp7_l1_7 = gp7_l0_14 ^ gp7_l0_15;
wire gp7_l1_8 = gp7_l0_16 ^ gp7_l0_17;
wire gp7_l1_9 = gp7_l0_18 ^ gp7_l0_19;
wire gp7_l1_10 = gp7_l0_20 ^ gp7_l0_21;
wire gp7_l1_11 = gp7_l0_22 ^ gp7_l0_23;
wire gp7_l1_12 = gp7_l0_24 ^ gp7_l0_25;
wire gp7_l1_13 = gp7_l0_26 ^ gp7_l0_27;
wire gp7_l1_14 = gp7_l0_28 ^ gp7_l0_29;
wire gp7_l1_15 = gp7_l0_30 ^ gp7_l0_31;
wire gp7_l1_16 = gp7_l0_32 ^ gp7_l0_33;
wire gp7_l1_17 = gp7_l0_34 ^ gen_parity[6];
wire gp7_l2_0 = gp7_l1_0 ^ gp7_l1_1;
wire gp7_l2_1 = gp7_l1_2 ^ gp7_l1_3;
wire gp7_l2_2 = gp7_l1_4 ^ gp7_l1_5;
wire gp7_l2_3 = gp7_l1_6 ^ gp7_l1_7;
wire gp7_l2_4 = gp7_l1_8 ^ gp7_l1_9;
wire gp7_l2_5 = gp7_l1_10 ^ gp7_l1_11;
wire gp7_l2_6 = gp7_l1_12 ^ gp7_l1_13;
wire gp7_l2_7 = gp7_l1_14 ^ gp7_l1_15;
wire gp7_l2_8 = gp7_l1_16 ^ gp7_l1_17;
wire gp7_l3_0 = gp7_l2_0 ^ gp7_l2_1;
wire gp7_l3_1 = gp7_l2_2 ^ gp7_l2_3;
wire gp7_l3_2 = gp7_l2_4 ^ gp7_l2_5;
wire gp7_l3_3 = gp7_l2_6 ^ gp7_l2_7;
wire gp7_l4_0 = gp7_l3_0 ^ gp7_l3_1;
wire gp7_l4_1 = gp7_l3_2 ^ gp7_l3_3;
wire gp7_l5_0 = gp7_l4_0 ^ gp7_l4_1;
wire gp7_l6_0 = gp7_l5_0 ^ gp7_l2_8;
assign gen_parity[7] = gp7_l6_0;


//------------------------------------------------------------------------------
// Pipeline Stage 1 — Register encode inputs & parity
//------------------------------------------------------------------------------
reg [63:0] s1_data;
reg [7:0]  s1_parity;
reg        s1_encode, s1_decode, s1_valid;
reg [71:0] s1_codeword_in;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s1_data       <= 64'b0;
        s1_parity     <= 8'b0;
        s1_encode     <= 1'b0;
        s1_decode     <= 1'b0;
        s1_valid      <= 1'b0;
        s1_codeword_in<= 72'b0;
    end else begin
        s1_data        <= data_in;
        s1_parity      <= gen_parity;
        s1_encode      <= op_encode & valid_in;
        s1_decode      <= op_decode & valid_in;
        s1_valid       <= valid_in;
        s1_codeword_in <= codeword_in;
    end
end

//------------------------------------------------------------------------------
// Pipeline Stage 2 — Encode output / Syndrome decode
//------------------------------------------------------------------------------

// Syndrome: XOR received parity with recomputed parity over received data
wire [63:0] rx_data    = s1_codeword_in[71:8];
wire [7:0]  rx_parity  = s1_codeword_in[7:0];

// Recompute parity over received data for syndrome
// =========================================================
// Balanced-tree parity check (decode side)
// =========================================================
wire [7:0] chk_p;
wire cp0_l0_0 = rx_data[0] ^ rx_data[1];
wire cp0_l0_1 = rx_data[3] ^ rx_data[4];
wire cp0_l0_2 = rx_data[6] ^ rx_data[8];
wire cp0_l0_3 = rx_data[10] ^ rx_data[11];
wire cp0_l0_4 = rx_data[13] ^ rx_data[15];
wire cp0_l0_5 = rx_data[17] ^ rx_data[19];
wire cp0_l0_6 = rx_data[21] ^ rx_data[23];
wire cp0_l0_7 = rx_data[25] ^ rx_data[26];
wire cp0_l0_8 = rx_data[28] ^ rx_data[30];
wire cp0_l0_9 = rx_data[32] ^ rx_data[34];
wire cp0_l0_10 = rx_data[36] ^ rx_data[38];
wire cp0_l0_11 = rx_data[40] ^ rx_data[42];
wire cp0_l0_12 = rx_data[44] ^ rx_data[46];
wire cp0_l0_13 = rx_data[48] ^ rx_data[50];
wire cp0_l0_14 = rx_data[52] ^ rx_data[54];
wire cp0_l0_15 = rx_data[56] ^ rx_data[57];
wire cp0_l0_16 = rx_data[59] ^ rx_data[61];
wire cp0_l1_0 = cp0_l0_0 ^ cp0_l0_1;
wire cp0_l1_1 = cp0_l0_2 ^ cp0_l0_3;
wire cp0_l1_2 = cp0_l0_4 ^ cp0_l0_5;
wire cp0_l1_3 = cp0_l0_6 ^ cp0_l0_7;
wire cp0_l1_4 = cp0_l0_8 ^ cp0_l0_9;
wire cp0_l1_5 = cp0_l0_10 ^ cp0_l0_11;
wire cp0_l1_6 = cp0_l0_12 ^ cp0_l0_13;
wire cp0_l1_7 = cp0_l0_14 ^ cp0_l0_15;
wire cp0_l1_8 = cp0_l0_16 ^ rx_data[63];
wire cp0_l2_0 = cp0_l1_0 ^ cp0_l1_1;
wire cp0_l2_1 = cp0_l1_2 ^ cp0_l1_3;
wire cp0_l2_2 = cp0_l1_4 ^ cp0_l1_5;
wire cp0_l2_3 = cp0_l1_6 ^ cp0_l1_7;
wire cp0_l3_0 = cp0_l2_0 ^ cp0_l2_1;
wire cp0_l3_1 = cp0_l2_2 ^ cp0_l2_3;
wire cp0_l4_0 = cp0_l3_0 ^ cp0_l3_1;
wire cp0_l5_0 = cp0_l4_0 ^ cp0_l1_8;
assign chk_p[0] = cp0_l5_0;

wire cp1_l0_0 = rx_data[0] ^ rx_data[2];
wire cp1_l0_1 = rx_data[3] ^ rx_data[5];
wire cp1_l0_2 = rx_data[6] ^ rx_data[9];
wire cp1_l0_3 = rx_data[10] ^ rx_data[12];
wire cp1_l0_4 = rx_data[13] ^ rx_data[16];
wire cp1_l0_5 = rx_data[17] ^ rx_data[20];
wire cp1_l0_6 = rx_data[21] ^ rx_data[24];
wire cp1_l0_7 = rx_data[25] ^ rx_data[27];
wire cp1_l0_8 = rx_data[28] ^ rx_data[31];
wire cp1_l0_9 = rx_data[32] ^ rx_data[35];
wire cp1_l0_10 = rx_data[36] ^ rx_data[39];
wire cp1_l0_11 = rx_data[40] ^ rx_data[43];
wire cp1_l0_12 = rx_data[44] ^ rx_data[47];
wire cp1_l0_13 = rx_data[48] ^ rx_data[51];
wire cp1_l0_14 = rx_data[52] ^ rx_data[55];
wire cp1_l0_15 = rx_data[56] ^ rx_data[58];
wire cp1_l0_16 = rx_data[59] ^ rx_data[62];
wire cp1_l1_0 = cp1_l0_0 ^ cp1_l0_1;
wire cp1_l1_1 = cp1_l0_2 ^ cp1_l0_3;
wire cp1_l1_2 = cp1_l0_4 ^ cp1_l0_5;
wire cp1_l1_3 = cp1_l0_6 ^ cp1_l0_7;
wire cp1_l1_4 = cp1_l0_8 ^ cp1_l0_9;
wire cp1_l1_5 = cp1_l0_10 ^ cp1_l0_11;
wire cp1_l1_6 = cp1_l0_12 ^ cp1_l0_13;
wire cp1_l1_7 = cp1_l0_14 ^ cp1_l0_15;
wire cp1_l1_8 = cp1_l0_16 ^ rx_data[63];
wire cp1_l2_0 = cp1_l1_0 ^ cp1_l1_1;
wire cp1_l2_1 = cp1_l1_2 ^ cp1_l1_3;
wire cp1_l2_2 = cp1_l1_4 ^ cp1_l1_5;
wire cp1_l2_3 = cp1_l1_6 ^ cp1_l1_7;
wire cp1_l3_0 = cp1_l2_0 ^ cp1_l2_1;
wire cp1_l3_1 = cp1_l2_2 ^ cp1_l2_3;
wire cp1_l4_0 = cp1_l3_0 ^ cp1_l3_1;
wire cp1_l5_0 = cp1_l4_0 ^ cp1_l1_8;
assign chk_p[1] = cp1_l5_0;

wire cp2_l0_0 = rx_data[1] ^ rx_data[2];
wire cp2_l0_1 = rx_data[3] ^ rx_data[7];
wire cp2_l0_2 = rx_data[8] ^ rx_data[9];
wire cp2_l0_3 = rx_data[10] ^ rx_data[14];
wire cp2_l0_4 = rx_data[15] ^ rx_data[16];
wire cp2_l0_5 = rx_data[17] ^ rx_data[22];
wire cp2_l0_6 = rx_data[23] ^ rx_data[24];
wire cp2_l0_7 = rx_data[25] ^ rx_data[29];
wire cp2_l0_8 = rx_data[30] ^ rx_data[31];
wire cp2_l0_9 = rx_data[32] ^ rx_data[37];
wire cp2_l0_10 = rx_data[38] ^ rx_data[39];
wire cp2_l0_11 = rx_data[40] ^ rx_data[45];
wire cp2_l0_12 = rx_data[46] ^ rx_data[47];
wire cp2_l0_13 = rx_data[48] ^ rx_data[53];
wire cp2_l0_14 = rx_data[54] ^ rx_data[55];
wire cp2_l0_15 = rx_data[56] ^ rx_data[60];
wire cp2_l0_16 = rx_data[61] ^ rx_data[62];
wire cp2_l1_0 = cp2_l0_0 ^ cp2_l0_1;
wire cp2_l1_1 = cp2_l0_2 ^ cp2_l0_3;
wire cp2_l1_2 = cp2_l0_4 ^ cp2_l0_5;
wire cp2_l1_3 = cp2_l0_6 ^ cp2_l0_7;
wire cp2_l1_4 = cp2_l0_8 ^ cp2_l0_9;
wire cp2_l1_5 = cp2_l0_10 ^ cp2_l0_11;
wire cp2_l1_6 = cp2_l0_12 ^ cp2_l0_13;
wire cp2_l1_7 = cp2_l0_14 ^ cp2_l0_15;
wire cp2_l1_8 = cp2_l0_16 ^ rx_data[63];
wire cp2_l2_0 = cp2_l1_0 ^ cp2_l1_1;
wire cp2_l2_1 = cp2_l1_2 ^ cp2_l1_3;
wire cp2_l2_2 = cp2_l1_4 ^ cp2_l1_5;
wire cp2_l2_3 = cp2_l1_6 ^ cp2_l1_7;
wire cp2_l3_0 = cp2_l2_0 ^ cp2_l2_1;
wire cp2_l3_1 = cp2_l2_2 ^ cp2_l2_3;
wire cp2_l4_0 = cp2_l3_0 ^ cp2_l3_1;
wire cp2_l5_0 = cp2_l4_0 ^ cp2_l1_8;
assign chk_p[2] = cp2_l5_0;

wire cp3_l0_0 = rx_data[4] ^ rx_data[5];
wire cp3_l0_1 = rx_data[6] ^ rx_data[7];
wire cp3_l0_2 = rx_data[8] ^ rx_data[9];
wire cp3_l0_3 = rx_data[10] ^ rx_data[18];
wire cp3_l0_4 = rx_data[19] ^ rx_data[20];
wire cp3_l0_5 = rx_data[21] ^ rx_data[22];
wire cp3_l0_6 = rx_data[23] ^ rx_data[24];
wire cp3_l0_7 = rx_data[25] ^ rx_data[33];
wire cp3_l0_8 = rx_data[34] ^ rx_data[35];
wire cp3_l0_9 = rx_data[36] ^ rx_data[37];
wire cp3_l0_10 = rx_data[38] ^ rx_data[39];
wire cp3_l0_11 = rx_data[40] ^ rx_data[49];
wire cp3_l0_12 = rx_data[50] ^ rx_data[51];
wire cp3_l0_13 = rx_data[52] ^ rx_data[53];
wire cp3_l0_14 = rx_data[54] ^ rx_data[55];
wire cp3_l1_0 = cp3_l0_0 ^ cp3_l0_1;
wire cp3_l1_1 = cp3_l0_2 ^ cp3_l0_3;
wire cp3_l1_2 = cp3_l0_4 ^ cp3_l0_5;
wire cp3_l1_3 = cp3_l0_6 ^ cp3_l0_7;
wire cp3_l1_4 = cp3_l0_8 ^ cp3_l0_9;
wire cp3_l1_5 = cp3_l0_10 ^ cp3_l0_11;
wire cp3_l1_6 = cp3_l0_12 ^ cp3_l0_13;
wire cp3_l1_7 = cp3_l0_14 ^ rx_data[56];
wire cp3_l2_0 = cp3_l1_0 ^ cp3_l1_1;
wire cp3_l2_1 = cp3_l1_2 ^ cp3_l1_3;
wire cp3_l2_2 = cp3_l1_4 ^ cp3_l1_5;
wire cp3_l2_3 = cp3_l1_6 ^ cp3_l1_7;
wire cp3_l3_0 = cp3_l2_0 ^ cp3_l2_1;
wire cp3_l3_1 = cp3_l2_2 ^ cp3_l2_3;
wire cp3_l4_0 = cp3_l3_0 ^ cp3_l3_1;
assign chk_p[3] = cp3_l4_0;

wire cp4_l0_0 = rx_data[11] ^ rx_data[12];
wire cp4_l0_1 = rx_data[13] ^ rx_data[14];
wire cp4_l0_2 = rx_data[15] ^ rx_data[16];
wire cp4_l0_3 = rx_data[17] ^ rx_data[18];
wire cp4_l0_4 = rx_data[19] ^ rx_data[20];
wire cp4_l0_5 = rx_data[21] ^ rx_data[22];
wire cp4_l0_6 = rx_data[23] ^ rx_data[24];
wire cp4_l0_7 = rx_data[25] ^ rx_data[41];
wire cp4_l0_8 = rx_data[42] ^ rx_data[43];
wire cp4_l0_9 = rx_data[44] ^ rx_data[45];
wire cp4_l0_10 = rx_data[46] ^ rx_data[47];
wire cp4_l0_11 = rx_data[48] ^ rx_data[49];
wire cp4_l0_12 = rx_data[50] ^ rx_data[51];
wire cp4_l0_13 = rx_data[52] ^ rx_data[53];
wire cp4_l0_14 = rx_data[54] ^ rx_data[55];
wire cp4_l1_0 = cp4_l0_0 ^ cp4_l0_1;
wire cp4_l1_1 = cp4_l0_2 ^ cp4_l0_3;
wire cp4_l1_2 = cp4_l0_4 ^ cp4_l0_5;
wire cp4_l1_3 = cp4_l0_6 ^ cp4_l0_7;
wire cp4_l1_4 = cp4_l0_8 ^ cp4_l0_9;
wire cp4_l1_5 = cp4_l0_10 ^ cp4_l0_11;
wire cp4_l1_6 = cp4_l0_12 ^ cp4_l0_13;
wire cp4_l1_7 = cp4_l0_14 ^ rx_data[56];
wire cp4_l2_0 = cp4_l1_0 ^ cp4_l1_1;
wire cp4_l2_1 = cp4_l1_2 ^ cp4_l1_3;
wire cp4_l2_2 = cp4_l1_4 ^ cp4_l1_5;
wire cp4_l2_3 = cp4_l1_6 ^ cp4_l1_7;
wire cp4_l3_0 = cp4_l2_0 ^ cp4_l2_1;
wire cp4_l3_1 = cp4_l2_2 ^ cp4_l2_3;
wire cp4_l4_0 = cp4_l3_0 ^ cp4_l3_1;
assign chk_p[4] = cp4_l4_0;

wire cp5_l0_0 = rx_data[26] ^ rx_data[27];
wire cp5_l0_1 = rx_data[28] ^ rx_data[29];
wire cp5_l0_2 = rx_data[30] ^ rx_data[31];
wire cp5_l0_3 = rx_data[32] ^ rx_data[33];
wire cp5_l0_4 = rx_data[34] ^ rx_data[35];
wire cp5_l0_5 = rx_data[36] ^ rx_data[37];
wire cp5_l0_6 = rx_data[38] ^ rx_data[39];
wire cp5_l0_7 = rx_data[40] ^ rx_data[41];
wire cp5_l0_8 = rx_data[42] ^ rx_data[43];
wire cp5_l0_9 = rx_data[44] ^ rx_data[45];
wire cp5_l0_10 = rx_data[46] ^ rx_data[47];
wire cp5_l0_11 = rx_data[48] ^ rx_data[49];
wire cp5_l0_12 = rx_data[50] ^ rx_data[51];
wire cp5_l0_13 = rx_data[52] ^ rx_data[53];
wire cp5_l0_14 = rx_data[54] ^ rx_data[55];
wire cp5_l1_0 = cp5_l0_0 ^ cp5_l0_1;
wire cp5_l1_1 = cp5_l0_2 ^ cp5_l0_3;
wire cp5_l1_2 = cp5_l0_4 ^ cp5_l0_5;
wire cp5_l1_3 = cp5_l0_6 ^ cp5_l0_7;
wire cp5_l1_4 = cp5_l0_8 ^ cp5_l0_9;
wire cp5_l1_5 = cp5_l0_10 ^ cp5_l0_11;
wire cp5_l1_6 = cp5_l0_12 ^ cp5_l0_13;
wire cp5_l1_7 = cp5_l0_14 ^ rx_data[56];
wire cp5_l2_0 = cp5_l1_0 ^ cp5_l1_1;
wire cp5_l2_1 = cp5_l1_2 ^ cp5_l1_3;
wire cp5_l2_2 = cp5_l1_4 ^ cp5_l1_5;
wire cp5_l2_3 = cp5_l1_6 ^ cp5_l1_7;
wire cp5_l3_0 = cp5_l2_0 ^ cp5_l2_1;
wire cp5_l3_1 = cp5_l2_2 ^ cp5_l2_3;
wire cp5_l4_0 = cp5_l3_0 ^ cp5_l3_1;
assign chk_p[5] = cp5_l4_0;

wire cp6_l0_0 = rx_data[57] ^ rx_data[58];
wire cp6_l0_1 = rx_data[59] ^ rx_data[60];
wire cp6_l0_2 = rx_data[61] ^ rx_data[62];
wire cp6_l1_0 = cp6_l0_0 ^ cp6_l0_1;
wire cp6_l1_1 = cp6_l0_2 ^ rx_data[63];
wire cp6_l2_0 = cp6_l1_0 ^ cp6_l1_1;
assign chk_p[6] = cp6_l2_0;

wire cp7_l0_0 = rx_data[0] ^ rx_data[1];
wire cp7_l0_1 = rx_data[2] ^ rx_data[3];
wire cp7_l0_2 = rx_data[4] ^ rx_data[5];
wire cp7_l0_3 = rx_data[6] ^ rx_data[7];
wire cp7_l0_4 = rx_data[8] ^ rx_data[9];
wire cp7_l0_5 = rx_data[10] ^ rx_data[11];
wire cp7_l0_6 = rx_data[12] ^ rx_data[13];
wire cp7_l0_7 = rx_data[14] ^ rx_data[15];
wire cp7_l0_8 = rx_data[16] ^ rx_data[17];
wire cp7_l0_9 = rx_data[18] ^ rx_data[19];
wire cp7_l0_10 = rx_data[20] ^ rx_data[21];
wire cp7_l0_11 = rx_data[22] ^ rx_data[23];
wire cp7_l0_12 = rx_data[24] ^ rx_data[25];
wire cp7_l0_13 = rx_data[26] ^ rx_data[27];
wire cp7_l0_14 = rx_data[28] ^ rx_data[29];
wire cp7_l0_15 = rx_data[30] ^ rx_data[31];
wire cp7_l0_16 = rx_data[32] ^ rx_data[33];
wire cp7_l0_17 = rx_data[34] ^ rx_data[35];
wire cp7_l0_18 = rx_data[36] ^ rx_data[37];
wire cp7_l0_19 = rx_data[38] ^ rx_data[39];
wire cp7_l0_20 = rx_data[40] ^ rx_data[41];
wire cp7_l0_21 = rx_data[42] ^ rx_data[43];
wire cp7_l0_22 = rx_data[44] ^ rx_data[45];
wire cp7_l0_23 = rx_data[46] ^ rx_data[47];
wire cp7_l0_24 = rx_data[48] ^ rx_data[49];
wire cp7_l0_25 = rx_data[50] ^ rx_data[51];
wire cp7_l0_26 = rx_data[52] ^ rx_data[53];
wire cp7_l0_27 = rx_data[54] ^ rx_data[55];
wire cp7_l0_28 = rx_data[56] ^ rx_data[57];
wire cp7_l0_29 = rx_data[58] ^ rx_data[59];
wire cp7_l0_30 = rx_data[60] ^ rx_data[61];
wire cp7_l0_31 = rx_data[62] ^ rx_data[63];
wire cp7_l0_32 = rx_parity[0] ^ rx_parity[1];
wire cp7_l0_33 = rx_parity[2] ^ rx_parity[3];
wire cp7_l0_34 = rx_parity[4] ^ rx_parity[5];
wire cp7_l1_0 = cp7_l0_0 ^ cp7_l0_1;
wire cp7_l1_1 = cp7_l0_2 ^ cp7_l0_3;
wire cp7_l1_2 = cp7_l0_4 ^ cp7_l0_5;
wire cp7_l1_3 = cp7_l0_6 ^ cp7_l0_7;
wire cp7_l1_4 = cp7_l0_8 ^ cp7_l0_9;
wire cp7_l1_5 = cp7_l0_10 ^ cp7_l0_11;
wire cp7_l1_6 = cp7_l0_12 ^ cp7_l0_13;
wire cp7_l1_7 = cp7_l0_14 ^ cp7_l0_15;
wire cp7_l1_8 = cp7_l0_16 ^ cp7_l0_17;
wire cp7_l1_9 = cp7_l0_18 ^ cp7_l0_19;
wire cp7_l1_10 = cp7_l0_20 ^ cp7_l0_21;
wire cp7_l1_11 = cp7_l0_22 ^ cp7_l0_23;
wire cp7_l1_12 = cp7_l0_24 ^ cp7_l0_25;
wire cp7_l1_13 = cp7_l0_26 ^ cp7_l0_27;
wire cp7_l1_14 = cp7_l0_28 ^ cp7_l0_29;
wire cp7_l1_15 = cp7_l0_30 ^ cp7_l0_31;
wire cp7_l1_16 = cp7_l0_32 ^ cp7_l0_33;
wire cp7_l1_17 = cp7_l0_34 ^ rx_parity[6];
wire cp7_l2_0 = cp7_l1_0 ^ cp7_l1_1;
wire cp7_l2_1 = cp7_l1_2 ^ cp7_l1_3;
wire cp7_l2_2 = cp7_l1_4 ^ cp7_l1_5;
wire cp7_l2_3 = cp7_l1_6 ^ cp7_l1_7;
wire cp7_l2_4 = cp7_l1_8 ^ cp7_l1_9;
wire cp7_l2_5 = cp7_l1_10 ^ cp7_l1_11;
wire cp7_l2_6 = cp7_l1_12 ^ cp7_l1_13;
wire cp7_l2_7 = cp7_l1_14 ^ cp7_l1_15;
wire cp7_l2_8 = cp7_l1_16 ^ cp7_l1_17;
wire cp7_l3_0 = cp7_l2_0 ^ cp7_l2_1;
wire cp7_l3_1 = cp7_l2_2 ^ cp7_l2_3;
wire cp7_l3_2 = cp7_l2_4 ^ cp7_l2_5;
wire cp7_l3_3 = cp7_l2_6 ^ cp7_l2_7;
wire cp7_l4_0 = cp7_l3_0 ^ cp7_l3_1;
wire cp7_l4_1 = cp7_l3_2 ^ cp7_l3_3;
wire cp7_l5_0 = cp7_l4_0 ^ cp7_l4_1;
wire cp7_l6_0 = cp7_l5_0 ^ cp7_l2_8;
assign chk_p[7] = cp7_l6_0;

wire [7:0]  syndrome   = rx_parity ^ chk_p;
wire        single_err = syndrome[7];          // overall parity mismatch = odd # errors (1 bit)
wire        double_err = (syndrome[6:0] != 7'b0) & ~syndrome[7]; // nonzero 7b syndrome, even overall parity = 2-bit error

// Map syndrome[6:0] -> codeword bit index in error (Hamming SECDED bit-position code).
// syndrome[6:0] directly encodes a unique value 0..71 corresponding to the
// erroneous codeword bit (parity bits 0..7 and data bits 8..71).
reg [6:0] err_bit_idx;
always @(*) begin
    case (syndrome[6:0])
            7'd 0: err_bit_idx = 7'd 7;
            7'd 1: err_bit_idx = 7'd 0;
            7'd 2: err_bit_idx = 7'd 1;
            7'd 3: err_bit_idx = 7'd 8;
            7'd 4: err_bit_idx = 7'd 2;
            7'd 5: err_bit_idx = 7'd 9;
            7'd 6: err_bit_idx = 7'd10;
            7'd 7: err_bit_idx = 7'd11;
            7'd 8: err_bit_idx = 7'd 3;
            7'd 9: err_bit_idx = 7'd12;
            7'd10: err_bit_idx = 7'd13;
            7'd11: err_bit_idx = 7'd14;
            7'd12: err_bit_idx = 7'd15;
            7'd13: err_bit_idx = 7'd16;
            7'd14: err_bit_idx = 7'd17;
            7'd15: err_bit_idx = 7'd18;
            7'd16: err_bit_idx = 7'd 4;
            7'd17: err_bit_idx = 7'd19;
            7'd18: err_bit_idx = 7'd20;
            7'd19: err_bit_idx = 7'd21;
            7'd20: err_bit_idx = 7'd22;
            7'd21: err_bit_idx = 7'd23;
            7'd22: err_bit_idx = 7'd24;
            7'd23: err_bit_idx = 7'd25;
            7'd24: err_bit_idx = 7'd26;
            7'd25: err_bit_idx = 7'd27;
            7'd26: err_bit_idx = 7'd28;
            7'd27: err_bit_idx = 7'd29;
            7'd28: err_bit_idx = 7'd30;
            7'd29: err_bit_idx = 7'd31;
            7'd30: err_bit_idx = 7'd32;
            7'd31: err_bit_idx = 7'd33;
            7'd32: err_bit_idx = 7'd 5;
            7'd33: err_bit_idx = 7'd34;
            7'd34: err_bit_idx = 7'd35;
            7'd35: err_bit_idx = 7'd36;
            7'd36: err_bit_idx = 7'd37;
            7'd37: err_bit_idx = 7'd38;
            7'd38: err_bit_idx = 7'd39;
            7'd39: err_bit_idx = 7'd40;
            7'd40: err_bit_idx = 7'd41;
            7'd41: err_bit_idx = 7'd42;
            7'd42: err_bit_idx = 7'd43;
            7'd43: err_bit_idx = 7'd44;
            7'd44: err_bit_idx = 7'd45;
            7'd45: err_bit_idx = 7'd46;
            7'd46: err_bit_idx = 7'd47;
            7'd47: err_bit_idx = 7'd48;
            7'd48: err_bit_idx = 7'd49;
            7'd49: err_bit_idx = 7'd50;
            7'd50: err_bit_idx = 7'd51;
            7'd51: err_bit_idx = 7'd52;
            7'd52: err_bit_idx = 7'd53;
            7'd53: err_bit_idx = 7'd54;
            7'd54: err_bit_idx = 7'd55;
            7'd55: err_bit_idx = 7'd56;
            7'd56: err_bit_idx = 7'd57;
            7'd57: err_bit_idx = 7'd58;
            7'd58: err_bit_idx = 7'd59;
            7'd59: err_bit_idx = 7'd60;
            7'd60: err_bit_idx = 7'd61;
            7'd61: err_bit_idx = 7'd62;
            7'd62: err_bit_idx = 7'd63;
            7'd63: err_bit_idx = 7'd64;
            7'd64: err_bit_idx = 7'd 6;
            7'd65: err_bit_idx = 7'd65;
            7'd66: err_bit_idx = 7'd66;
            7'd67: err_bit_idx = 7'd67;
            7'd68: err_bit_idx = 7'd68;
            7'd69: err_bit_idx = 7'd69;
            7'd70: err_bit_idx = 7'd70;
            7'd71: err_bit_idx = 7'd71;
        default: err_bit_idx = 7'd0;
    endcase
end

// Bit-flip correction at the located bit position
wire [71:0] corrected_cw;
genvar gi;
generate
    for (gi = 0; gi < 72; gi = gi + 1) begin : gen_correct
        assign corrected_cw[gi] = (single_err && (err_bit_idx == gi[6:0]))
                                   ? ~s1_codeword_in[gi]
                                   : s1_codeword_in[gi];
    end
endgenerate

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        codeword_out      <= 72'b0;
        data_out          <= 64'b0;
        ecc_corrected     <= 1'b0;
        ecc_uncorrectable <= 1'b0;
        valid_out         <= 1'b0;
    end else begin
        valid_out         <= s1_valid;

        if (s1_encode) begin
            codeword_out <= {s1_data, s1_parity};
        end

        if (s1_decode) begin
            // Update status flags only on a new decode; otherwise hold
            // their value so downstream logic/testbenches have a full
            // cycle to observe a corrected/uncorrectable result.
            ecc_corrected     <= 1'b0;
            ecc_uncorrectable <= 1'b0;
            if (syndrome == 8'b0) begin
                data_out <= s1_codeword_in[71:8];
            end else if (single_err) begin
                data_out          <= corrected_cw[71:8];
                ecc_corrected     <= 1'b1;
            end else begin
                data_out          <= s1_codeword_in[71:8];
                ecc_uncorrectable <= 1'b1;
            end
        end
    end
end

//------------------------------------------------------------------------------
// SVA Assertions
//------------------------------------------------------------------------------
`ifdef SIMULATION
// op_encode and op_decode must not be asserted simultaneously
property p_no_simultaneous_op;
    @(posedge clk) disable iff (!rst_n)
    !(op_encode && op_decode);
endproperty
a_no_sim_op: assert property (p_no_simultaneous_op)
    else $error("[ECC] op_encode and op_decode asserted simultaneously at t=%0t", $time);

// valid_out must follow valid_in after 2 pipeline stages
property p_valid_pipeline;
    @(posedge clk) disable iff (!rst_n)
    valid_in |=> ##1 valid_out;
endproperty
a_valid_pipe: assert property (p_valid_pipeline)
    else $error("[ECC] valid_out pipeline violation at t=%0t", $time);

// ecc_corrected and ecc_uncorrectable must not both be set
property p_no_dual_ecc_flag;
    @(posedge clk) disable iff (!rst_n)
    !(ecc_corrected && ecc_uncorrectable);
endproperty
a_no_dual_flag: assert property (p_no_dual_ecc_flag)
    else $error("[ECC] Both ecc_corrected and ecc_uncorrectable set at t=%0t", $time);

// Cover: single-bit correction occurred
c_single_bit_corrected: cover property (
    @(posedge clk) disable iff (!rst_n) ecc_corrected);

// Cover: double-bit error detected
c_double_bit_detected: cover property (
    @(posedge clk) disable iff (!rst_n) ecc_uncorrectable);
`endif

endmodule
`default_nettype wire
//==============================================================================
// Module      : training_fsm
// Project     : DDR5 Memory Subsystem SoC
// Description : DDR5 Initialization & Training Sequence Controller
//               - JEDEC JESD79-5B compliant state machine
//               - tINIT5 = 2ms = 200,000 cycles @ 100MHz
//               - Per-byte-lane independent Vref sweep
//               - Write Leveling, Read DQ Gate Training, Vref Training
//               - SVA protocol assertions
// FIX         : Array port best_vref[0:NUM_LANES-1] flattened to
//               best_vref0, best_vref1 — Verilog-2001 compatible
// Author      : VVR | IIITDM Kurnool Internship
// Spec Ref    : JEDEC JESD79-5B Section 3.3, 4.7, 4.8
// Node        : 45nm   Target Freq : 500 MHz
//==============================================================================
`default_nettype none
`timescale 1ns/1ps

module training_fsm #(
    parameter CLK_FREQ_MHZ  = 100,
    parameter TINIT5_US     = 2000,
    parameter INIT_CYCLES   = 200000,   // CLK_FREQ_MHZ * TINIT5_US
    parameter WL_PULSES     = 8,
    parameter RDQ_PULSES    = 16,
    parameter VREF_STEPS    = 64,
    parameter EYE_THRESHOLD = 8'd30
) (
    input  wire        clk,
    input  wire        rst_n,

    // AXI4-Lite control
    input  wire        train_start,
    input  wire [1:0]  train_mode,    // 0=WL, 1=RDQ, 2=VREF, 3=FULL

    // PHY interface
    output reg         phy_cal_req,
    output reg  [7:0]  phy_vref_code,
    output reg  [1:0]  phy_lane_sel,
    input  wire        phy_cal_ack,
    input  wire [7:0]  phy_eye_data,

    // Outputs
    output reg         training_done,
    output reg         training_error,
    output reg  [7:0]  eye_margin,

    // FIX: flattened per-lane Vref outputs (no array ports)
    output reg  [7:0]  best_vref0,    // Lane 0 best Vref
    output reg  [7:0]  best_vref1,    // Lane 1 best Vref

    output reg  [3:0]  fsm_state_out
);

//------------------------------------------------------------------------------
// FSM State Encoding
//------------------------------------------------------------------------------
localparam [3:0]
    S_IDLE       = 4'd0,
    S_INIT_WAIT  = 4'd1,
    S_ZQ_CAL     = 4'd2,
    S_WL_SETUP   = 4'd3,
    S_WL_PULSE   = 4'd4,
    S_WL_SAMPLE  = 4'd5,
    S_RDQ_SETUP  = 4'd6,
    S_RDQ_PULSE  = 4'd7,
    S_RDQ_SAMPLE = 4'd8,
    S_VREF_SETUP = 4'd9,
    S_VREF_PULSE = 4'd10,
    S_VREF_EVAL  = 4'd11,
    S_DONE       = 4'd12,
    S_ERROR      = 4'd13;

//------------------------------------------------------------------------------
// Internal registers
//------------------------------------------------------------------------------
reg [3:0]  state, next_state;
reg [17:0] init_cnt;
reg [4:0]  pulse_cnt;
reg [6:0]  vref_step;
reg [1:0]  lane_idx;

// Per-lane tracking (internal arrays — OK inside module)
reg [7:0]  lane_best_margin [0:1];
reg [7:0]  lane_best_vref   [0:1];
reg [7:0]  global_best_margin;

integer i;

//------------------------------------------------------------------------------
// Sequential state register
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= S_IDLE;
    else        state <= next_state;
end

//------------------------------------------------------------------------------
// Combinational next-state logic
//------------------------------------------------------------------------------
always @(*) begin
    next_state = state;
    case (state)
        S_IDLE:
            if (train_start) next_state = S_INIT_WAIT;

        S_INIT_WAIT:
            if (init_cnt == 18'd0) next_state = S_ZQ_CAL;

        S_ZQ_CAL:
            if (phy_cal_ack)
                next_state = (train_mode == 2'd1) ? S_RDQ_SETUP :
                             (train_mode == 2'd2) ? S_VREF_SETUP :
                             S_WL_SETUP;

        S_WL_SETUP:  next_state = S_WL_PULSE;

        S_WL_PULSE:
            if (phy_cal_ack) next_state = S_WL_SAMPLE;

        S_WL_SAMPLE:
            if (pulse_cnt == WL_PULSES-1) begin
                if (lane_idx == 1'b1) begin
                    if (train_mode == 2'd0) next_state = S_DONE;
                    else                    next_state = S_RDQ_SETUP;
                end else
                    next_state = S_WL_SETUP;
            end else
                next_state = S_WL_PULSE;

        S_RDQ_SETUP: next_state = S_RDQ_PULSE;

        S_RDQ_PULSE:
            if (phy_cal_ack) next_state = S_RDQ_SAMPLE;

        S_RDQ_SAMPLE:
            if (pulse_cnt == RDQ_PULSES-1) begin
                if (lane_idx == 1'b1) begin
                    if (train_mode == 2'd1) next_state = S_DONE;
                    else                    next_state = S_VREF_SETUP;
                end else
                    next_state = S_RDQ_SETUP;
            end else
                next_state = S_RDQ_PULSE;

        S_VREF_SETUP: next_state = S_VREF_PULSE;

        S_VREF_PULSE:
            if (phy_cal_ack) next_state = S_VREF_EVAL;

        S_VREF_EVAL:
            if (vref_step == VREF_STEPS-1) begin
                if (lane_idx == 1'b1) next_state = S_DONE;
                else                   next_state = S_VREF_SETUP;
            end else
                next_state = S_VREF_PULSE;

        S_DONE:
            if (global_best_margin < EYE_THRESHOLD)
                next_state = S_ERROR;

        S_ERROR:   next_state = S_IDLE;
        default:   next_state = S_IDLE;
    endcase
end

//------------------------------------------------------------------------------
// Sequential datapath
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        training_done   <= 1'b0;
        training_error  <= 1'b0;
        phy_cal_req     <= 1'b0;
        phy_vref_code   <= 8'b0;
        phy_lane_sel    <= 2'b0;
        eye_margin      <= 8'b0;
        best_vref0      <= 8'b0;
        best_vref1      <= 8'b0;
        init_cnt        <= INIT_CYCLES[17:0];
        pulse_cnt       <= 5'b0;
        vref_step       <= 7'b0;
        lane_idx        <= 1'b0;
        global_best_margin    <= 8'b0;
        lane_best_margin[0]   <= 8'b0;
        lane_best_margin[1]   <= 8'b0;
        lane_best_vref[0]     <= 8'b0;
        lane_best_vref[1]     <= 8'b0;
    end else begin
        phy_cal_req    <= 1'b0;
        training_done  <= 1'b0;
        training_error <= 1'b0;

        case (state)

            S_IDLE: begin
                init_cnt             <= INIT_CYCLES[17:0];
                pulse_cnt            <= 5'b0;
                vref_step            <= 7'b0;
                lane_idx             <= 1'b0;
                global_best_margin   <= 8'b0;
                lane_best_margin[0]  <= 8'b0;
                lane_best_margin[1]  <= 8'b0;
                lane_best_vref[0]    <= 8'b0;
                lane_best_vref[1]    <= 8'b0;
            end

            S_INIT_WAIT:
                if (init_cnt > 18'd0) init_cnt <= init_cnt - 1'b1;

            S_ZQ_CAL:
                phy_cal_req <= 1'b1;

            S_WL_SETUP: begin
                pulse_cnt    <= 5'b0;
                phy_lane_sel <= lane_idx;
            end

            S_WL_PULSE:
                phy_cal_req <= 1'b1;

            S_WL_SAMPLE: begin
                if (phy_eye_data > lane_best_margin[lane_idx])
                    lane_best_margin[lane_idx] <= phy_eye_data;
                if (pulse_cnt == WL_PULSES-1) begin
                    if (lane_idx == 1'b0) begin
                        lane_idx  <= 1'b1;
                        pulse_cnt <= 5'b0;
                    end
                end else
                    pulse_cnt <= pulse_cnt + 1'b1;
            end

            S_RDQ_SETUP: begin
                pulse_cnt    <= 5'b0;
                phy_lane_sel <= lane_idx;
            end

            S_RDQ_PULSE:
                phy_cal_req <= 1'b1;

            S_RDQ_SAMPLE: begin
                if (phy_eye_data > lane_best_margin[lane_idx])
                    lane_best_margin[lane_idx] <= phy_eye_data;
                if (pulse_cnt == RDQ_PULSES-1) begin
                    if (lane_idx == 1'b0) begin
                        lane_idx  <= 1'b1;
                        pulse_cnt <= 5'b0;
                    end
                end else
                    pulse_cnt <= pulse_cnt + 1'b1;
            end

            S_VREF_SETUP: begin
                vref_step    <= 7'b0;
                phy_lane_sel <= lane_idx;
            end

            S_VREF_PULSE: begin
                phy_cal_req   <= 1'b1;
                phy_vref_code <= {1'b0, vref_step[6:0]};
            end

            S_VREF_EVAL: begin
                if (phy_eye_data > lane_best_margin[lane_idx]) begin
                    lane_best_margin[lane_idx] <= phy_eye_data;
                    lane_best_vref[lane_idx]   <= {1'b0, vref_step[6:0]};
                end
                if (vref_step == VREF_STEPS-1) begin
                    if (lane_idx == 1'b0) begin
                        lane_idx  <= 1'b1;
                        vref_step <= 7'b0;
                    end
                end else
                    vref_step <= vref_step + 1'b1;
            end

            S_DONE: begin
                // Global best = worst lane (system limited by weakest lane)
                global_best_margin <= (lane_best_margin[0] < lane_best_margin[1])
                                       ? lane_best_margin[0] : lane_best_margin[1];
                eye_margin <= global_best_margin;
                // Drive flattened output ports
                best_vref0     <= lane_best_vref[0];
                best_vref1     <= lane_best_vref[1];
                training_done  <= 1'b1;
            end

            S_ERROR: begin
                training_error <= 1'b1;
                training_done  <= 1'b0;
            end

        endcase
    end
end

always @(*) fsm_state_out = state;

//------------------------------------------------------------------------------
// SVA Assertions
//------------------------------------------------------------------------------
`ifdef SIMULATION

property p_done_not_in_error;
    @(posedge clk) disable iff (!rst_n)
    (state == S_ERROR) |-> !training_done;
endproperty
a_done_error: assert property (p_done_not_in_error)
    else $error("[TRAIN] training_done in ERROR state t=%0t", $time);

property p_cal_req_pulse;
    @(posedge clk) disable iff (!rst_n)
    $rose(phy_cal_req) |-> ##[1:5] !phy_cal_req;
endproperty
a_cal_pulse: assert property (p_cal_req_pulse)
    else $error("[TRAIN] phy_cal_req stuck high t=%0t", $time);

property p_done_error_mutex;
    @(posedge clk) disable iff (!rst_n)
    !(training_done && training_error);
endproperty
a_done_error_mutex: assert property (p_done_error_mutex)
    else $error("[TRAIN] training_done and training_error both high t=%0t", $time);

c_full_training:  cover property (@(posedge clk) disable iff(!rst_n)
    (train_mode==2'd3) && training_done);
c_training_error: cover property (@(posedge clk) disable iff(!rst_n)
    training_error);
`endif

endmodule
`default_nettype wire
//==============================================================================
// Module      : bank_group_scheduler
// Project     : DDR5 Memory Subsystem SoC
// Description : FR-FCFS Bank Group Interleaving Scheduler
//               - DDR5: 4 Bank Groups x 4 Banks = 16 Banks
//               - Full DDR5 timings: tRCD,tCL,tRP,tRAS,tFAW,tRRD_L,tRRD_S
//               - tFAW (Four Activate Window) per JEDEC JESD79-5B
//               - Per-Bank Refresh (PBR) with tREFI countdown
//               - 16-entry Reorder Buffer (ROB)
//               - FR-FCFS row-hit prioritization
//               - SVA timing assertions
// FIX         : req_ready and cmd_ready_out changed from assign to always
//               automatic variables replaced with named regs (Verilog-2001)
// Author      : VVR | IIITDM Kurnool Internship
// Spec Ref    : JEDEC JESD79-5B Table 169 (DDR5-4800 timings)
// Node        : 45nm   Target Freq : 500 MHz
//==============================================================================
`default_nettype none
`timescale 1ns/1ps

module bank_group_scheduler #(
    parameter NUM_BG      = 4,
    parameter NUM_BANKS   = 4,
    parameter TOTAL_BANKS = 16,
    parameter ROB_DEPTH   = 16,
    parameter ROW_BITS    = 17,
    parameter COL_BITS    = 11,
    // DDR5-4800 timings @ 500MHz (2ns ck)
    parameter tRCD        = 18,
    parameter tCL         = 18,
    parameter tRP         = 18,
    parameter tRAS        = 38,
    parameter tRRD_L      = 5,
    parameter tRRD_S      = 4,
    parameter tFAW        = 20,
    parameter tREFI       = 3900,
    parameter tRFC_PB     = 115
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        training_done,

    // Request interface
    input  wire [31:0] req_addr,
    input  wire        req_valid,
    input  wire        req_type,    // 0=RD, 1=WR
    output reg         req_ready,

    // Command output to ECC / PHY
    output reg         cmd_valid,
    output reg  [1:0]  cmd_bg,
    output reg  [1:0]  cmd_bank,
    output reg  [16:0] cmd_row,
    output reg  [10:0] cmd_col,
    output reg         cmd_rw,
    output reg  [2:0]  cmd_op,
    output reg         cmd_ready_out,

    // Status
    output reg  [4:0]  rob_count
);

//------------------------------------------------------------------------------
// Opcodes
//------------------------------------------------------------------------------
localparam NOP=3'd0, ACT=3'd1, RD=3'd2, WR=3'd3, PRE=3'd4, REF=3'd5;

//------------------------------------------------------------------------------
// ROB entry width: {type(1), row(17), col(11), BG(2), bank(2)} = 33 bits
//------------------------------------------------------------------------------
localparam REQ_W = 33;

reg [REQ_W-1:0] rob       [0:ROB_DEPTH-1];
reg             rob_valid  [0:ROB_DEPTH-1];
reg [3:0]       rob_head, rob_tail;

//------------------------------------------------------------------------------
// Bank state arrays
//------------------------------------------------------------------------------
reg             bank_open        [0:TOTAL_BANKS-1];
reg [16:0]      bank_open_row    [0:TOTAL_BANKS-1];
reg [5:0]       bank_cd          [0:TOTAL_BANKS-1];
reg [11:0]      bank_refi        [0:TOTAL_BANKS-1];
reg [7:0]       bank_rfc         [0:TOTAL_BANKS-1];
reg             bank_ref_pend    [0:TOTAL_BANKS-1];

// tFAW window: 4 slots tracking ACT ages
reg [4:0]       faw_timer        [0:3];
reg [2:0]       faw_count;

// tRRD per-BG last-ACT age
reg [4:0]       bg_last_act      [0:NUM_BG-1];

//------------------------------------------------------------------------------
// FSM states
//------------------------------------------------------------------------------
localparam [2:0]
    FS_IDLE = 3'd0,
    FS_SEL  = 3'd1,
    FS_PRE  = 3'd2,
    FS_ACT  = 3'd3,
    FS_CAS  = 3'd4,
    FS_REF  = 3'd5,
    FS_WAIT = 3'd6;

reg [2:0]  fstate;
reg [7:0]  wait_cnt;
reg [2:0]  next_cmd_r;

// Current transaction registers
reg [1:0]  cur_bg, cur_bank;
reg [16:0] cur_row;
reg [10:0] cur_col;
reg        cur_rw;
reg [3:0]  cur_bidx;

// FR-FCFS selection outputs (combinational)
reg [3:0]  sched_idx;
reg        sched_valid;
reg        sched_refresh;
reg [3:0]  ref_bidx;
reg [1:0]  ref_bg, ref_bank;

integer k;

//------------------------------------------------------------------------------
// ROB Enqueue
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rob_head  <= 4'b0;
        rob_tail  <= 4'b0;
        rob_count <= 5'b0;
        for (k=0; k<ROB_DEPTH; k=k+1)
            rob_valid[k] <= 1'b0;
    end else begin
        if (req_valid && req_ready) begin
            // Pack: {type, row[16:0], col[10:0], BG[1:0], bank[1:0]}
            rob[rob_tail]       <= { req_type,
                                     req_addr[31:15],   // row
                                     req_addr[14:4],    // col
                                     req_addr[3:2],     // BG
                                     req_addr[1:0] };   // bank
            rob_valid[rob_tail] <= 1'b1;
            rob_tail            <= rob_tail + 1'b1;
            rob_count           <= rob_count + 1'b1;
        end
    end
end

//------------------------------------------------------------------------------
// req_ready — combinational via always (FIX: was assign with reg)
//------------------------------------------------------------------------------
always @(*) begin
    req_ready = training_done && (rob_count < ROB_DEPTH);
end

//------------------------------------------------------------------------------
// Per-Bank Timer Decrement & tREFI
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (k=0; k<TOTAL_BANKS; k=k+1) begin
            bank_open[k]      <= 1'b0;
            bank_open_row[k]  <= 17'b0;
            bank_cd[k]        <= 6'b0;
            bank_refi[k]      <= tREFI[11:0];
            bank_rfc[k]       <= 8'b0;
            bank_ref_pend[k]  <= 1'b0;
        end
        for (k=0; k<4; k=k+1)    faw_timer[k]    <= 5'b0;
        for (k=0; k<NUM_BG; k=k+1) bg_last_act[k] <= 5'b0;
        faw_count <= 3'b0;
    end else begin
        for (k=0; k<TOTAL_BANKS; k=k+1) begin
            if (bank_cd[k]  > 0) bank_cd[k]  <= bank_cd[k]  - 1'b1;
            if (bank_rfc[k] > 0) bank_rfc[k] <= bank_rfc[k] - 1'b1;
            if (bank_refi[k] == 12'd0) begin
                bank_ref_pend[k] <= 1'b1;
                bank_refi[k]     <= tREFI[11:0];
            end else
                bank_refi[k] <= bank_refi[k] - 1'b1;
        end
        // Age tFAW slots
        for (k=0; k<4; k=k+1)
            if (faw_timer[k] > 0) faw_timer[k] <= faw_timer[k] - 1'b1;
        faw_count <= (faw_timer[0]>0) + (faw_timer[1]>0) +
                     (faw_timer[2]>0) + (faw_timer[3]>0);
        // Age tRRD
        for (k=0; k<NUM_BG; k=k+1)
            if (bg_last_act[k] > 0) bg_last_act[k] <= bg_last_act[k] - 1'b1;
    end
end

//------------------------------------------------------------------------------
// FR-FCFS Selection (combinational)
// Named regs replace 'automatic' variables — Verilog-2001 compatible
//------------------------------------------------------------------------------
reg [1:0]  sc_bg, sc_bank;
reg [3:0]  sc_bidx;
reg [16:0] sc_row;
reg [3:0]  sc_idx_i;

always @(*) begin
    sched_idx     = rob_head;
    sched_valid   = 1'b0;
    sched_refresh = 1'b0;
    ref_bidx      = 4'b0;
    ref_bg        = 2'b0;
    ref_bank      = 2'b0;

    // Priority 1: Per-Bank Refresh pending
    for (k=0; k<TOTAL_BANKS; k=k+1) begin
        if (bank_ref_pend[k] && bank_rfc[k]==8'b0 && !sched_refresh) begin
            sched_refresh = 1'b1;
            ref_bidx      = k[3:0];
            ref_bg        = k[3:2];
            ref_bank      = k[1:0];
        end
    end

    if (!sched_refresh) begin
        // Priority 2: Row Hit scan (FR-FCFS)
        for (k=0; k<ROB_DEPTH; k=k+1) begin
            sc_idx_i = (rob_head + k[3:0]) & 4'hF;
            sc_bg    = rob[sc_idx_i][3:2];
            sc_bank  = rob[sc_idx_i][1:0];
            sc_bidx  = {sc_bg, sc_bank};
            sc_row   = rob[sc_idx_i][28:12];
            if (rob_valid[sc_idx_i] && !sched_valid &&
                bank_open[sc_bidx] &&
                bank_open_row[sc_bidx] == sc_row &&
                bank_cd[sc_bidx] == 6'b0) begin
                sched_idx   = sc_idx_i;
                sched_valid = 1'b1;
            end
        end
        // Priority 3: FCFS fallback
        if (!sched_valid && rob_valid[rob_head]) begin
            sc_bidx = {rob[rob_head][3:2], rob[rob_head][1:0]};
            if (bank_cd[sc_bidx] == 6'b0) begin
                sched_idx   = rob_head;
                sched_valid = 1'b1;
            end
        end
    end
end

//------------------------------------------------------------------------------
// Scheduler FSM
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        fstate        <= FS_IDLE;
        cmd_valid     <= 1'b0;
        cmd_op        <= NOP;
        cmd_ready_out <= 1'b1;
        wait_cnt      <= 8'b0;
        next_cmd_r    <= NOP;
        cur_bg        <= 2'b0; cur_bank  <= 2'b0;
        cur_row       <= 17'b0; cur_col  <= 11'b0;
        cur_rw        <= 1'b0; cur_bidx  <= 4'b0;
    end else begin
        cmd_valid     <= 1'b0;
        // FIX: cmd_ready_out driven in always block, not assign
        cmd_ready_out <= (fstate == FS_IDLE);

        case (fstate)

            FS_IDLE: begin
                if (sched_refresh) begin
                    cur_bidx <= ref_bidx;
                    cur_bg   <= ref_bg;
                    cur_bank <= ref_bank;
                    fstate   <= FS_REF;
                end else if (sched_valid) begin
                    cur_bg   <= rob[sched_idx][3:2];
                    cur_bank <= rob[sched_idx][1:0];
                    cur_bidx <= {rob[sched_idx][3:2], rob[sched_idx][1:0]};
                    cur_row  <= rob[sched_idx][28:12];
                    cur_col  <= rob[sched_idx][11:1];
                    cur_rw   <= rob[sched_idx][REQ_W-1];
                    rob_valid[sched_idx] <= 1'b0;
                    rob_head  <= rob_head + 1'b1;
                    rob_count <= rob_count - 1'b1;
                    fstate    <= FS_SEL;
                end
            end

            FS_SEL: begin
                if (bank_open[cur_bidx] &&
                    bank_open_row[cur_bidx] == cur_row) begin
                    // Row hit — go straight to CAS
                    fstate <= FS_CAS;
                end else if (bank_open[cur_bidx]) begin
                    // Row miss — need PRE first
                    cmd_valid <= 1'b1;
                    cmd_op    <= PRE;
                    cmd_bg    <= cur_bg;
                    cmd_bank  <= cur_bank;
                    bank_open[cur_bidx] <= 1'b0;
                    bank_cd[cur_bidx]   <= tRP[5:0];
                    wait_cnt            <= tRP[7:0];
                    next_cmd_r          <= ACT;
                    fstate              <= FS_WAIT;
                end else begin
                    // Bank closed — ACT directly
                    fstate <= FS_ACT;
                end
            end

            FS_WAIT: begin
                if (wait_cnt == 8'd0) begin
                    case (next_cmd_r)
                        ACT:     fstate <= FS_ACT;
                        default: fstate <= FS_CAS;
                    endcase
                end else
                    wait_cnt <= wait_cnt - 1'b1;
            end

            FS_ACT: begin
                // Wait for tFAW and tRRD clearance
                if ((faw_count < 3'd4) &&
                    (bg_last_act[cur_bg] == 5'b0) &&
                    (bank_cd[cur_bidx]   == 6'b0)) begin
                    cmd_valid             <= 1'b1;
                    cmd_op                <= ACT;
                    cmd_bg                <= cur_bg;
                    cmd_bank              <= cur_bank;
                    cmd_row               <= cur_row;
                    bank_open[cur_bidx]     <= 1'b1;
                    bank_open_row[cur_bidx] <= cur_row;
                    bank_cd[cur_bidx]       <= tRCD[5:0];
                    // Push new ACT into tFAW ring
                    faw_timer[0] <= faw_timer[1];
                    faw_timer[1] <= faw_timer[2];
                    faw_timer[2] <= faw_timer[3];
                    faw_timer[3] <= tFAW[4:0];
                    bg_last_act[cur_bg] <= tRRD_L[4:0];
                    wait_cnt   <= tRCD[7:0];
                    next_cmd_r <= WR;     // dummy — FSM goes to CAS
                    fstate     <= FS_WAIT;
                end
                // else stall (tFAW or tRRD not met)
            end

            FS_CAS: begin
                if (bank_cd[cur_bidx] == 6'b0) begin
                    cmd_valid <= 1'b1;
                    cmd_op    <= cur_rw ? WR : RD;
                    cmd_bg    <= cur_bg;
                    cmd_bank  <= cur_bank;
                    cmd_row   <= cur_row;
                    cmd_col   <= cur_col;
                    cmd_rw    <= cur_rw;
                    bank_cd[cur_bidx] <= tCL[5:0];
                    fstate    <= FS_IDLE;
                end
            end

            FS_REF: begin
                if (bank_open[cur_bidx]) begin
                    // Precharge before refresh
                    cmd_valid <= 1'b1;
                    cmd_op    <= PRE;
                    cmd_bg    <= cur_bg;
                    cmd_bank  <= cur_bank;
                    bank_open[cur_bidx] <= 1'b0;
                    wait_cnt  <= tRP[7:0] + tRFC_PB[7:0];
                end else begin
                    cmd_valid <= 1'b1;
                    cmd_op    <= REF;
                    cmd_bg    <= cur_bg;
                    cmd_bank  <= cur_bank;
                    bank_ref_pend[cur_bidx] <= 1'b0;
                    bank_rfc[cur_bidx]      <= tRFC_PB[7:0];
                    wait_cnt  <= tRFC_PB[7:0];
                end
                next_cmd_r <= NOP;
                fstate     <= FS_WAIT;
            end

            default: fstate <= FS_IDLE;
        endcase
    end
end

//------------------------------------------------------------------------------
// SVA Assertions
//------------------------------------------------------------------------------
`ifdef SIMULATION
// No command before training done
property p_train_gate;
    @(posedge clk) disable iff (!rst_n)
    !training_done |-> !(cmd_valid && cmd_op != NOP);
endproperty
a_train_gate: assert property (p_train_gate)
    else $error("[SCHED] CMD issued before training_done t=%0t", $time);

// tFAW: never exceed 4 ACTs in window
property p_faw;
    @(posedge clk) disable iff (!rst_n)
    (cmd_valid && cmd_op == ACT) |-> (faw_count < 3'd4);
endproperty
a_faw: assert property (p_faw)
    else $error("[SCHED] tFAW violation at t=%0t", $time);

// No back-to-back same-bank commands
property p_bank_gap;
    @(posedge clk) disable iff (!rst_n)
    (cmd_valid && cmd_op != NOP) |=>
        !(cmd_valid && cmd_op != NOP &&
          cmd_bg == $past(cmd_bg) && cmd_bank == $past(cmd_bank));
endproperty
a_bank_gap: assert property (p_bank_gap)
    else $error("[SCHED] Back-to-back same bank at t=%0t", $time);

// Coverage
c_row_hit:   cover property (@(posedge clk) disable iff(!rst_n)
    cmd_valid && (cmd_op==RD || cmd_op==WR));
c_refresh:   cover property (@(posedge clk) disable iff(!rst_n)
    cmd_valid && cmd_op==REF);
c_faw_near:  cover property (@(posedge clk) disable iff(!rst_n)
    faw_count == 3'd3);
`endif

endmodule
`default_nettype wire
//==============================================================================
// Module      : axi4lite_regs
// Project     : DDR5 Memory Subsystem SoC
// Description : AXI4-Lite CSR Register Bank
//               - Fully decoupled AW/W channels (industry standard)
//               - Outstanding write transaction support
//               - Read/write address decode with default response
//               - SVA AXI4-Lite protocol assertions
// Register Map:
//   0x00 TRAIN_CTRL   [1:0]=mode [2]=start(pulse)
//   0x04 TRAIN_STATUS [0]=done [1]=error [9:2]=eye_margin [12:10]=fsm_state
//   0x08 SCHED_CONFIG [3:0]=bg_enable [4]=rob_flush
//   0x0C ECC_STATUS   [0]=corrected [1]=uncorrectable [9:2]=syndrome (RO)
//   0x10 MEM_ADDR     [31:0]=request address
//   0x14 MEM_CTRL     [0]=req_valid [1]=req_type(0=RD,1=WR)
//   0x18 LANE0_VREF   [7:0]=best_vref lane0 (RO)
//   0x1C LANE1_VREF   [7:0]=best_vref lane1 (RO)
// Author      : VVR | IIITDM Kurnool Internship
// Spec Ref    : ARM IHI0022E AXI4-Lite Specification
// Node        : 45nm
//==============================================================================
`default_nettype none
`timescale 1ns/1ps

module axi4lite_regs (
    input  wire        clk,
    input  wire        rst_n,

    // AXI4-Lite Write Address Channel
    input  wire [31:0] awaddr,
    input  wire        awvalid,
    output reg         awready,

    // AXI4-Lite Write Data Channel
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    input  wire        wvalid,
    output reg         wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]  bresp,
    output reg         bvalid,
    input  wire        bready,

    // AXI4-Lite Read Address Channel
    input  wire [31:0] araddr,
    input  wire        arvalid,
    output reg         arready,

    // AXI4-Lite Read Data Channel
    output reg  [31:0] rdata,
    output reg  [1:0]  rresp,
    output reg         rvalid,
    input  wire        rready,

    // To Training FSM
    output reg         train_start,
    output reg  [1:0]  train_mode,

    // From Training FSM
    input  wire        training_done,
    input  wire        training_error,
    input  wire [7:0]  eye_margin,
    input  wire [3:0]  fsm_state,
    input  wire [7:0]  lane0_vref,
    input  wire [7:0]  lane1_vref,

    // To Scheduler
    output reg         req_valid,
    output reg  [31:0] req_addr,
    output reg         req_type,
    input  wire        req_ready_in,

    // From ECC Engine
    input  wire        ecc_corrected,
    input  wire        ecc_uncorrectable
);

// AXI4-Lite RESP codes
localparam OKAY   = 2'b00;
localparam SLVERR = 2'b10;

// Register addresses
localparam ADDR_TRAIN_CTRL   = 5'h00;
localparam ADDR_TRAIN_STATUS = 5'h04;
localparam ADDR_SCHED_CONFIG = 5'h08;
localparam ADDR_ECC_STATUS   = 5'h0C;
localparam ADDR_MEM_ADDR     = 5'h10;
localparam ADDR_MEM_CTRL     = 5'h14;
localparam ADDR_LANE0_VREF   = 5'h18;
localparam ADDR_LANE1_VREF   = 5'h1C;

// Internal shadow registers
reg [31:0] reg_train_ctrl;
reg [31:0] reg_sched_config;
reg [31:0] reg_mem_addr;
reg [31:0] reg_mem_ctrl;

// Decouple AW and W channels — latch address separately
reg [31:0] aw_addr_lat;
reg        aw_addr_valid;
reg        w_data_valid;
reg [31:0] w_data_lat;
reg [3:0]  w_strb_lat;

//------------------------------------------------------------------------------
// Write Address Channel — accept and latch
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        awready      <= 1'b0;
        aw_addr_lat  <= 32'b0;
        aw_addr_valid<= 1'b0;
    end else begin
        awready <= 1'b0;
        if (awvalid && !aw_addr_valid) begin
            awready       <= 1'b1;
            aw_addr_lat   <= awaddr;
            aw_addr_valid <= 1'b1;
        end
        // Clear once write completes
        if (bvalid && bready) aw_addr_valid <= 1'b0;
    end
end

//------------------------------------------------------------------------------
// Write Data Channel — accept and latch
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wready      <= 1'b0;
        w_data_lat  <= 32'b0;
        w_strb_lat  <= 4'b0;
        w_data_valid<= 1'b0;
    end else begin
        wready <= 1'b0;
        if (wvalid && !w_data_valid) begin
            wready      <= 1'b1;
            w_data_lat  <= wdata;
            w_strb_lat  <= wstrb;
            w_data_valid<= 1'b1;
        end
        if (bvalid && bready) w_data_valid <= 1'b0;
    end
end

//------------------------------------------------------------------------------
// Write Execute + Response — fires when both AW and W are latched
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bvalid        <= 1'b0;
        bresp         <= OKAY;
        reg_train_ctrl   <= 32'b0;
        reg_sched_config <= 32'hF;
        reg_mem_addr     <= 32'b0;
        reg_mem_ctrl     <= 32'b0;
        train_start   <= 1'b0;
        train_mode    <= 2'b0;
        req_valid     <= 1'b0;
        req_type      <= 1'b0;
        req_addr      <= 32'b0;
    end else begin
        train_start <= 1'b0;  // pulse — deassert every cycle
        req_valid   <= 1'b0;

        if (aw_addr_valid && w_data_valid && !bvalid) begin
            bresp  <= OKAY;
            bvalid <= 1'b1;

            // Byte-strobe aware write
            case (aw_addr_lat[4:0])
                ADDR_TRAIN_CTRL: begin
                    if (w_strb_lat[0]) reg_train_ctrl[7:0]   <= w_data_lat[7:0];
                    if (w_strb_lat[1]) reg_train_ctrl[15:8]  <= w_data_lat[15:8];
                    train_start <= w_data_lat[2];
                    train_mode  <= w_data_lat[1:0];
                end
                ADDR_SCHED_CONFIG: begin
                    if (w_strb_lat[0]) reg_sched_config[7:0] <= w_data_lat[7:0];
                end
                ADDR_MEM_ADDR: begin
                    if (w_strb_lat[0]) reg_mem_addr[7:0]   <= w_data_lat[7:0];
                    if (w_strb_lat[1]) reg_mem_addr[15:8]  <= w_data_lat[15:8];
                    if (w_strb_lat[2]) reg_mem_addr[23:16] <= w_data_lat[23:16];
                    if (w_strb_lat[3]) reg_mem_addr[31:24] <= w_data_lat[31:24];
                end
                ADDR_MEM_CTRL: begin
                    if (w_strb_lat[0]) reg_mem_ctrl[7:0] <= w_data_lat[7:0];
                    req_valid <= w_data_lat[0];
                    req_type  <= w_data_lat[1];
                    req_addr  <= reg_mem_addr;
                end
                // Write to RO registers → SLVERR
                ADDR_TRAIN_STATUS,
                ADDR_ECC_STATUS,
                ADDR_LANE0_VREF,
                ADDR_LANE1_VREF: bresp <= SLVERR;
                default: bresp <= SLVERR;
            endcase
        end

        if (bvalid && bready) bvalid <= 1'b0;
    end
end

//------------------------------------------------------------------------------
// Read Channel
//------------------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        arready <= 1'b0;
        rvalid  <= 1'b0;
        rdata   <= 32'b0;
        rresp   <= OKAY;
    end else begin
        arready <= 1'b0;
        rvalid  <= 1'b0;

        if (arvalid && !rvalid) begin
            arready <= 1'b1;
            rvalid  <= 1'b1;
            rresp   <= OKAY;
            case (araddr[4:0])
                ADDR_TRAIN_CTRL:
                    rdata <= reg_train_ctrl;
                ADDR_TRAIN_STATUS:
                    rdata <= {19'b0, fsm_state, eye_margin, training_error, training_done};
                ADDR_SCHED_CONFIG:
                    rdata <= reg_sched_config;
                ADDR_ECC_STATUS:
                    rdata <= {30'b0, ecc_uncorrectable, ecc_corrected};
                ADDR_MEM_ADDR:
                    rdata <= reg_mem_addr;
                ADDR_MEM_CTRL:
                    rdata <= reg_mem_ctrl;
                ADDR_LANE0_VREF:
                    rdata <= {24'b0, lane0_vref};
                ADDR_LANE1_VREF:
                    rdata <= {24'b0, lane1_vref};
                default: begin
                    rdata <= 32'hDEAD_BEEF;
                    rresp <= SLVERR;
                end
            endcase
        end

        if (rvalid && rready) rvalid <= 1'b0;
    end
end

//------------------------------------------------------------------------------
// SVA AXI4-Lite Protocol Assertions
//------------------------------------------------------------------------------
`ifdef SIMULATION
// AWVALID must not deassert until AWREADY
property p_aw_stable;
    @(posedge clk) disable iff (!rst_n)
    awvalid && !awready |=> awvalid;
endproperty
a_aw_stable: assert property (p_aw_stable)
    else $error("[AXI] AWVALID deasserted before AWREADY at t=%0t", $time);

// WVALID must not deassert until WREADY
property p_w_stable;
    @(posedge clk) disable iff (!rst_n)
    wvalid && !wready |=> wvalid;
endproperty
a_w_stable: assert property (p_w_stable)
    else $error("[AXI] WVALID deasserted before WREADY at t=%0t", $time);

// BVALID must stay until BREADY
property p_b_stable;
    @(posedge clk) disable iff (!rst_n)
    bvalid && !bready |=> bvalid;
endproperty
a_b_stable: assert property (p_b_stable)
    else $error("[AXI] BVALID deasserted before BREADY at t=%0t", $time);

// RVALID must stay until RREADY
property p_r_stable;
    @(posedge clk) disable iff (!rst_n)
    rvalid && !rready |=> rvalid;
endproperty
a_r_stable: assert property (p_r_stable)
    else $error("[AXI] RVALID deasserted before RREADY at t=%0t", $time);

// train_start must be a single-cycle pulse
property p_train_pulse;
    @(posedge clk) disable iff (!rst_n)
    $rose(train_start) |=> !train_start;
endproperty
a_train_pulse: assert property (p_train_pulse)
    else $error("[AXI] train_start not a single-cycle pulse at t=%0t", $time);

// Coverage: each register written at least once
c_write_train_ctrl:   cover property (@(posedge clk) bvalid && aw_addr_lat[4:0]==ADDR_TRAIN_CTRL);
c_write_mem_addr:     cover property (@(posedge clk) bvalid && aw_addr_lat[4:0]==ADDR_MEM_ADDR);
c_read_train_status:  cover property (@(posedge clk) rvalid && araddr[4:0]==ADDR_TRAIN_STATUS);
c_read_ecc_status:    cover property (@(posedge clk) rvalid && araddr[4:0]==ADDR_ECC_STATUS);
c_slverr_response:    cover property (@(posedge clk) bvalid && bresp==SLVERR);
`endif

endmodule
`default_nettype wire
//==============================================================================
// Module      : ddr5_subsystem_top
// Project     : DDR5 Memory Subsystem SoC
// Description : Top-level integration
//               - AXI4-Lite Register Bank
//               - DDR5 Training FSM (fixed: flattened Vref ports)
//               - Bank Group Interleaving Scheduler
//               - On-Die ECC Engine (SECDED 72,64)
// Author      : VVR | IIITDM Kurnool Internship
// Node        : 45nm
//==============================================================================
`default_nettype none
`timescale 1ns/1ps

module ddr5_subsystem_top (
    input  wire        clk,
    input  wire        rst_n,

    // AXI4-Lite Host Interface
    input  wire [31:0] awaddr,
    input  wire        awvalid,
    output wire        awready,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    input  wire        wvalid,
    output wire        wready,
    output wire [1:0]  bresp,
    output wire        bvalid,
    input  wire        bready,
    input  wire [31:0] araddr,
    input  wire        arvalid,
    output wire        arready,
    output wire [31:0] rdata,
    output wire [1:0]  rresp,
    output wire        rvalid,
    input  wire        rready,

    // PHY Interface
    output wire        phy_cal_req,
    input  wire        phy_cal_ack,
    input  wire [7:0]  phy_eye_data,
    output wire [71:0] phy_tx_data,
    input  wire [71:0] phy_rx_data,
    output wire        phy_cmd_valid,
    output wire [2:0]  phy_cmd_op,
    output wire [1:0]  phy_cmd_bg,
    output wire [1:0]  phy_cmd_bank,
    output wire [16:0] phy_cmd_row,
    output wire [10:0] phy_cmd_col,

    // Status outputs
    output wire        training_done,
    output wire [7:0]  eye_margin,
    output wire        ecc_corrected,
    output wire        ecc_uncorrectable
);

//------------------------------------------------------------------------------
// Internal wires
//------------------------------------------------------------------------------
wire        train_start_w;
wire [1:0]  train_mode_w;
wire        training_error_w;
wire [7:0]  vref_code_w;         // lane 0 vref (used for PHY)
wire [7:0]  best_vref0_w;
wire [7:0]  best_vref1_w;
wire [3:0]  training_state_w;
wire [7:0]  phy_vref_code_w;
wire [1:0]  phy_lane_sel_w;

wire        sched_req_valid;
wire [31:0] sched_req_addr;
wire        sched_req_type;
wire        sched_req_ready;
wire        sched_cmd_valid;
wire [1:0]  sched_cmd_bg, sched_cmd_bank;
wire [16:0] sched_cmd_row;
wire [10:0] sched_cmd_col;
wire        sched_cmd_rw;
wire [2:0]  sched_cmd_op;

wire [71:0] ecc_codeword_out;
wire [63:0] ecc_data_out;
wire        ecc_valid_out;

wire [63:0] write_data = {wdata, wdata}; // Demo: expand 32→64 bit
wire        ecc_encode_v = sched_cmd_valid && sched_cmd_rw;
wire        ecc_decode_v = sched_cmd_valid && !sched_cmd_rw;

//------------------------------------------------------------------------------
// AXI4-Lite Register Bank
//------------------------------------------------------------------------------
axi4lite_regs u_axi_regs (
    .clk              (clk),
    .rst_n            (rst_n),
    .awaddr           (awaddr),   .awvalid (awvalid), .awready (awready),
    .wdata            (wdata),    .wstrb   (wstrb),
    .wvalid           (wvalid),   .wready  (wready),
    .bresp            (bresp),    .bvalid  (bvalid),  .bready  (bready),
    .araddr           (araddr),   .arvalid (arvalid), .arready (arready),
    .rdata            (rdata),    .rresp   (rresp),
    .rvalid           (rvalid),   .rready  (rready),
    .train_start      (train_start_w),
    .train_mode       (train_mode_w),
    .training_done    (training_done),
    .training_error   (training_error_w),
    .eye_margin       (eye_margin),
    .fsm_state        (training_state_w),      // FIX: was .training_state(training_state_w[2:0]); port is fsm_state[3:0]
    .lane0_vref       (best_vref0_w),          // FIX: added missing connection
    .lane1_vref       (best_vref1_w),          // FIX: added missing connection
    .req_valid        (sched_req_valid),
    .req_addr         (sched_req_addr),
    .req_type         (sched_req_type),
    .req_ready_in     (sched_req_ready),
    .ecc_corrected    (ecc_corrected),
    .ecc_uncorrectable(ecc_uncorrectable)
);

//------------------------------------------------------------------------------
// Training FSM
//------------------------------------------------------------------------------
training_fsm u_training (
    .clk              (clk),
    .rst_n            (rst_n),
    .train_start      (train_start_w),
    .train_mode       (train_mode_w),
    .phy_cal_req      (phy_cal_req),
    .phy_vref_code    (phy_vref_code_w),
    .phy_lane_sel     (phy_lane_sel_w),
    .phy_cal_ack      (phy_cal_ack),
    .phy_eye_data     (phy_eye_data),
    .training_done    (training_done),
    .training_error   (training_error_w),
    .eye_margin       (eye_margin),
    .best_vref0       (best_vref0_w),
    .best_vref1       (best_vref1_w),
    .fsm_state_out    (training_state_w)
);

//------------------------------------------------------------------------------
// Bank Group Scheduler
//------------------------------------------------------------------------------
bank_group_scheduler u_scheduler (
    .clk          (clk),
    .rst_n        (rst_n),
    .training_done(training_done),
    .req_valid    (sched_req_valid),
    .req_addr     (sched_req_addr),
    .req_type     (sched_req_type),
    .req_ready    (sched_req_ready),
    .cmd_valid    (sched_cmd_valid),
    .cmd_bg       (sched_cmd_bg),
    .cmd_bank     (sched_cmd_bank),
    .cmd_row      (sched_cmd_row),
    .cmd_col      (sched_cmd_col),
    .cmd_rw       (sched_cmd_rw),
    .cmd_op       (sched_cmd_op),
    .cmd_ready_out(),
    .rob_count    ()
);

assign phy_cmd_valid = sched_cmd_valid;
assign phy_cmd_op    = sched_cmd_op;
assign phy_cmd_bg    = sched_cmd_bg;
assign phy_cmd_bank  = sched_cmd_bank;
assign phy_cmd_row   = sched_cmd_row;
assign phy_cmd_col   = sched_cmd_col;

//------------------------------------------------------------------------------
// ECC Engine
//------------------------------------------------------------------------------
ecc_engine u_ecc (
    .clk              (clk),
    .rst_n            (rst_n),
    .op_encode        (ecc_encode_v),
    .op_decode        (ecc_decode_v),
    .valid_in         (sched_cmd_valid),
    .data_in          (write_data),
    .codeword_out     (phy_tx_data),
    .codeword_in      (phy_rx_data),
    .data_out         (ecc_data_out),
    .ecc_corrected    (ecc_corrected),
    .ecc_uncorrectable(ecc_uncorrectable),
    .valid_out        (ecc_valid_out)
);

endmodule
`default_nettype wire
