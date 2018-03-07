//
// This test harness is intended for use with the
// Basys3 development board.  The board provides
// a clock source and buttons for a reset
// signal.  The board provides a seven segment
// display and LEDs for output.  The switches are
// used to select which value to show on the seven
// segment display
//
// The harness instantiates the deep packet
// inspector and then uses data from a block RAM
// to stream data to the deep packet inspector.
// The output counters are provided to a large
// mux that connects to a seven segment display
// driver
//
module dpi_dev_harness (
  input            clk,
  input            rst,
  input      [3:0] sw,
  output     [6:0] seg7,
  output           dp,
  output     [3:0] an,
  output reg       led
);

  localparam SW_TOTAL_SEL       = 4'b0000;
  localparam SW_SKYPE_SEL       = 4'b0001;
  localparam SW_SKYPE_SESS_SEL  = 4'b0010;
  localparam SW_SSH_SEL         = 4'b0011;
  localparam SW_SSH_SESS_SEL    = 4'b0100;
  localparam SW_TELNET_SEL      = 4'b0101;
  localparam SW_TELNET_SESS_SEL = 4'b0110;
  localparam SW_FTP_SEL         = 4'b0111;
  localparam SW_HTTPS_SEL       = 4'b1000;
  localparam SW_SNMP_SEL        = 4'b1001;
  localparam SW_SMTP_SEL        = 4'b1010;
  localparam SW_NNTP_SEL        = 4'b1011;

  localparam INIT_STATE = 2'b00;
  localparam LATCH_DATA = 2'b01;
  localparam SHIFT_DATA = 2'b10;
  localparam DONE_STATE = 2'b11;

  wire        rst_n;

  reg  [13:0] hex_disp_val;
  wire [31:0] total_cnt;
  wire  [7:0] skype_cnt;
  wire  [7:0] ftp_cnt;
  wire  [7:0] https_cnt;
  wire  [7:0] ssh_cnt;
  wire  [7:0] telnet_cnt;
  wire  [7:0] snmp_cnt;
  wire  [7:0] smtp_cnt;
  wire  [7:0] nntp_cnt;
  wire  [7:0] skype_session;
  wire  [7:0] ssh_session;
  wire  [7:0] telnet_session;

  wire  [4:0] digit0;
  wire  [4:0] digit1;
  wire  [4:0] digit2;
  wire  [4:0] digit3;
  wire  [4:0] digit4;

  wire  [7:0] cathodes;

  reg  [11:0] mem_addr;
  wire  [7:0] mem_data;
  wire        mem_rst;
  wire        max_mem_addr;

  reg   [2:0] count;
  wire        count_tc;
  reg   [7:0] shift_reg;

  reg   [1:0] cstate, nstate;
  reg         load;
  reg         shift;

  // Saturating part of counter
  assign max_mem_addr = ( mem_addr == {12{1'b1}} );

  // instantiate block RAMs as simple memories that
  // have the contents preloaded from the Verilog
  // file itself

  // BRAM_SINGLE_MACRO: Single Port RAM
  //                    Artix-7
  // Xilinx HDL Language Template, version 2014.4
  
  /////////////////////////////////////////////////////////////////////
  //  READ_WIDTH | BRAM_SIZE | READ Depth  | ADDR Width |            //
  // WRITE_WIDTH |           | WRITE Depth |            |  WE Width  //
  // ============|===========|=============|============|============//
  //    37-72    |  "36Kb"   |      512    |    9-bit   |    8-bit   //
  //    19-36    |  "36Kb"   |     1024    |   10-bit   |    4-bit   //
  //    19-36    |  "18Kb"   |      512    |    9-bit   |    4-bit   //
  //    10-18    |  "36Kb"   |     2048    |   11-bit   |    2-bit   //
  //    10-18    |  "18Kb"   |     1024    |   10-bit   |    2-bit   //
  //     5-9     |  "36Kb"   |     4096    |   12-bit   |    1-bit   //
  //     5-9     |  "18Kb"   |     2048    |   11-bit   |    1-bit   //
  //     3-4     |  "36Kb"   |     8192    |   13-bit   |    1-bit   //
  //     3-4     |  "18Kb"   |     4096    |   12-bit   |    1-bit   //
  //       2     |  "36Kb"   |    16384    |   14-bit   |    1-bit   //
  //       2     |  "18Kb"   |     8192    |   13-bit   |    1-bit   //
  //       1     |  "36Kb"   |    32768    |   15-bit   |    1-bit   //
  //       1     |  "18Kb"   |    16384    |   14-bit   |    1-bit   //
  /////////////////////////////////////////////////////////////////////

  assign mem_rst = rst;
  assign rst_n   = !rst;
 
  BRAM_SINGLE_MACRO #(
    .BRAM_SIZE("36Kb"), // Target BRAM, "18Kb" or "36Kb" 
    .DEVICE("7SERIES"), // Target Device: "7SERIES" 
    .DO_REG(0), // Optional output register (0 or 1)
    .INIT(36'h000000000), // Initial values on output port
    .INIT_FILE ("NONE"),
    .WRITE_WIDTH(8), // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
    .READ_WIDTH(8),  // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
    .SRVAL(36'h000000000), // Set/Reset value for port output
    .WRITE_MODE("WRITE_FIRST"), // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE" 
    .INIT_00(256'hc4ca5b63c9ced34ea279023ba9c504b7501c17006d3174dc0ddb0604a5a5a5a5),
    .INIT_01(256'hcfe518e99ca995606f553308bfdfdd00376d5ecf0fb01583d2d2d252aca918f4),
    .INIT_02(256'h0824c05bfe24416af5b005804e1fc32fdb2d1478696969e9604c395b3021b51b),
    .INIT_03(256'hbeb07e42bf8502c0a3f3fb3e3c8819b3b4b4b474eaf79d09c19a17828a82a94a),
    .INIT_04(256'hce76b605f5319bde5b81fc575a5a5abafe3ee8b76814a9f75ae43c22943a7b34),
    .INIT_05(256'hdd65699e593d66282d2d2d3dad113da2a6880b11bdbb34088682a0d2ced0b624),
    .INIT_06(256'h1b39e096969696a2414162ba2c2d2d2d7506c51a8c03a87c36fe78d5bfb50090),
    .INIT_07(256'h4b4b4bb7a6d3b54f1e6205f3f6dc2992ce0aa0e2aa502f1d445e000464a31e1d),
    .INIT_08(256'hcdc259f990ddfc7027d44e5388e7af0987d558533f320028a2ba408339af0d4a),
    .INIT_09(256'h73bafd31290b2f3d7d085aa1165db4ccc2675b191cacf74d4ec0b0a5a5a5a5d0),
    .INIT_0A(256'h9d5b9c1f6b37f83ce82bbadcb3dd00a7b697b07194a7d1d2d2d2520ae1d46182),
    .INIT_0B(256'hf332a5a6b38f9e2ec76e400a4c484533684a4269696929190db35775921e41ce),
    .INIT_0C(256'h3aad35167d37a01dae56bce0414cbfb4b4b4f4d81f9343859a1e050871348dff),
    .INIT_0D(256'haebb0a8b592c9b67304d595a5a5aca9f471b6341a2026988a4ced11a24c02644),
    .INIT_0E(256'hef4417dbef382f2d2d2de5ea141f9e78d61d782b67a27b8cd22dc76f05b84a0e),
    .INIT_0F(256'ha940949696968efe6866292f2d2d2da585b832b1b1897fdf39710c55d15d3590),
    .INIT_10(256'h4b4bd9f7c791b097969696b66b3d00fb62bde9442c6ecb26eaae9605e94b55de),
    .INIT_11(256'h6d476c4b4b4b4b1de980f37a04c83973db1d52e82f00e22736cf1dd352e74a4b),
    .INIT_12(256'ha5a5a50cf19fb3f7018108f81ef692341600224aec739cc2fb3ea5a5a5a5f4ae),
    .INIT_13(256'h1998a3bf840bd3d8b4aa1abab3ad9e24396eafb91bf6d2d2d2d23d36cbd291a5),
    .INIT_14(256'h29ebce5d23cf61772880263d78d1dd6e9e41696969294a000aa5e6d2d2d2d2b7),
    .INIT_15(256'h9b7e92ea02a0ffb285da1e7aa9afb4b4b41429d151bd6df36753267e682e0dd3),
    .INIT_16(256'h01b0390ad4de01ad6a5c5a5a5afa0c6fe3eda6b4b4b47413f69d8d7b40fc57cb),
    .INIT_17(256'hee1aecb26c2e2d2d2d257dcf9964e588742c67b3b4c4cb6358ad71c3d9ef604d),
    .INIT_18(256'h02969696960e6601ced574e7b4265d1ad14a6b1220f910ce5f866fba008886e9),
    .INIT_19(256'h4b99d1d023a5d142a4dae86c368bffcccbcf1f99b97e7bebae0ab608622d9311),
    .INIT_1A(256'h154d1cda0377a151196a5775c30da3aeb18c92660484b6639e3a8fee074b4b4b),
    .INIT_1B(256'h6c0177493e98a999777d1faa2ca7cebaabe31dfbbe2c91c899a5a5a5a56cc430),
    .INIT_1C(256'hede52d01cb9e49ce2fe7eb0b00f73fe956a3e791aed2d2d2527848af94b2ae05),
    .INIT_1D(256'h9602805c9dc3f7d996719ddaa4b39d0d6769696929cb1d153bea735b03d07a27),
    .INIT_1E(256'h80216946803de6a4ef7bd772bab4b4b4f49fd9ab176d69696929e2eb6ae16e02),
    .INIT_1F(256'h40edd09a5c799c8b5b5a5a5a7a3a77e25fb2b4b4b414227feed534849e250694),
    .INIT_20(256'h69a26b042b2d2d2d1dd37b83184b162e01b310eebfbc4d70bda75340af3d7001),
    .INIT_21(256'h969696960250b433c685133450e43b5a2e98cc6dd8be0629a54ad90dc0420b19),
    .INIT_22(256'he77fa9915e949696962aa9f32f89246424472da1344e9f6d2d5702253e333ccb),
    .INIT_23(256'h8a4b4b4b4b49e7f287a2ab84bbd4c03acda67603f0e09b103f9effd14a4b4b4b),
    .INIT_24(256'h4a35ca64f5fb20fcc26d8f8d5802a100da92540a1d312cc5a5a5a5a5946951e9),
    .INIT_25(256'hc4d5c21c961a9883ede8dd00e1288efe2956a196d2d2d252287355eb45847b4b),
    .INIT_26(256'h2be20e13f583ee2af60a845a6d8d4c7c69696929968171d03e434e2f3e85e044),
    .INIT_27(256'h88291460e044cab4dfe10fb2b4b4b4944c8059a069696969e9dec2019f6f12b0),
    .INIT_28(256'he20b89d8c60d355c5a5a5a0a19c788dfbbf757dce824837005754400af5bfae5),
    .INIT_29(256'hee178d282d2d2d1da2c00fde5c5a5a5aaab5f676b6d4e6652cc7ab6f82a0bb9a),
    .INIT_2A(256'h969696fe2cc0f0662b2d2d2dbd3916e3a596275604014feed00805409a797dba),
    .INIT_2B(256'h14b4e3fb950cf757517aadd61109dc6ac09a736e5d5d00e4904f75c311891494),
    .INIT_2C(256'h943206536896523ad2729759f718449709430130272d17ebc85b524a4b4b4b91),
    .INIT_2D(256'hd041c126e926b03523b61e33251400488b4987e669978ea5a5a5a5131768b6ea),
    .INIT_2E(256'hc51bd1d533fba187d60c80f6c59fe101457bfcd2d2d252eed0354deda5a5a5a5),
    .INIT_2F(256'h8c1f8321afeeeab578bfe429136a76696969e9c5b600d3a201b7d5977ceb968a),
    .INIT_30(256'h2f03203aa1cb1a373b0fa9b4b4b494c5ee0bda85f088f61502f60c40c4eda078),
    .INIT_31(256'hbe5a493eb990505a5a5a8a401eff96c883fe942b04286a47a4549825de7e9222),
    .INIT_32(256'h60d22d2d2d2de589d793ddd075c8ba88b3006530a5a5a5a59997fb9fbc1b30f0),
    .INIT_33(256'h9696c2c56eb45d83f5c3833662bae5ac1770e395b95b0db6b10030099153e4a0),
    .INIT_34(256'h197e9aed7b3a4f136f4fb5d20870e9194f2c13a65c00880cfbd84b759f119596),
    .INIT_35(256'h6722c78c2bb4c6f8667ead2db56528f26604fa9afc081f4a18064a4b4b4b5f9c),
    .INIT_36(256'h635b039473e4649c9a4e05c7a1003a5884f3b6d417a7a5a5a5a57c91ea491d65),
    .INIT_37(256'h13e6abdf37bb5ff81901b967551e33396e91d2d2d25228e58deca555b99d795c),
    .INIT_38(256'h0146ee89ee2a3d5a8b2ece4e1f5e696969298d60f3a7d6d2d2d2d2f2e414baa9),
    .INIT_39(256'h03c044efd65339d356b1b4b4b4f42ea382255769696969916729073a5837a685),
    .INIT_3A(256'h6e302033365a5a5a5a0a598767d5bab4b4b4740c7911a075d48d4f5e3ce9fd32),
    .INIT_3B(256'h262b2d2d2dfd1d2fab706c5c98a6f8978871c9bc493d7996b91ec5be1b607b1c),
    .INIT_3C(256'h96c29f6e5f1d9a9932dac49b9f11791258dba73fadc52dbf00b08b6e075aab98),
    .INIT_3D(256'h36bea419b3f1be37f753a323740c92947bc8389f6df90ac5e30f20e380959696),
    .INIT_3E(256'h9be3e2c8462b0ee2cba711425afd467557f56f939e64fc17db4a4b4b4b8f8a5a),
    .INIT_3F(256'h7446ccdbe47d12808d3a20a100b951f625bf56092ba5a5a5a5071f37eb886a53),
    .INIT_40(256'hc097f0971f5bd9190119a6ea8aed499794d2d2d252ae8203a16787cf599661bf),
    .INIT_41(256'h3767f36ec0e978f72f92490e71696969e9c12d92ac1e17f3b6760bcf0eb7c12c),
    .INIT_42(256'h20b3ea9e68f5d24dbbb4b4b494593e38daaa6511469b45fe7a302fb38ad6ad8a),
    .INIT_43(256'h4335eaa7575a5a5a0a9c40a05e25b281feb1af3b3e4c866dbc1b379d5c869802),
    .INIT_44(256'h2d2d2d2dc5a3055a8a8914536744356b3e5fc514aaa3e3e367fe160ad0b1d049),
    .INIT_45(256'h924b250988348e1351172691285b2928abf3a115c3f4080518d9feff8a424b76),
    .INIT_46(256'h32977d1a81a3b06d3712006c9492dee387ce58004c8875bd6b26956995969696),
    .INIT_47(256'h4b2db8136764ae555c59d059c1ab42010aa874eead8b42924a4b4b4b4fa6c75e),
    .INIT_48(256'hf6d16231194c4c3c1211a1009efd3e9b98a9fa98a5a5a5a59c621e6bb04a4b4b),
    .INIT_49(256'h7f1d50cd4e8a5000b90d59bbaccdbebed2d2d2527615ecca373510a26e0d8e55),
    .INIT_4A(256'he46728801d54735ce0735c7d696969e9cb9715ad3f953ac48ddb6ac44d5afe6f),
    .INIT_4B(256'h6bc0269b0efd19a8b4b4b4f4302f6f32a10dd9e481f589f113bbecca4a5051d3),
    .INIT_4C(256'h053eb2565a5a5afac8da5c0bfff727c15a1954b4140477c31ebf26b7a1674660),
    .INIT_4D(256'h2d2d2d4530d2fba5b17f8b121cf2ada14f69720ad8baa6c8be1d0ad03589fc28),
    .INIT_4E(256'hd58fc7e843cf8f4ed2971e7251ccb7c7de851f0764d15dc5671b37731103ba2c),
    .INIT_4F(256'h969696966a102ac1fb59f5a5e4b02358c76400ec965208d63058b396969696d2),
    .INIT_50(256'hd1118494c207b67d08b68f9e0c2c00201d0a313442a6784b4b4b4b47a6f7d6db),
    .INIT_51(256'hf27e57fdd20333c4681400f0ad8364fd870680a5a5a5a5343cb352656f8465f0),
    .INIT_52(256'h035b404dcfb32d1a1427c805055cf4d2d2d25280c6b8b605a5a5a5a5c0890bfd),
    .INIT_53(256'h8b05800fae082178c78173696969e9149474b4d2d2d2d2d2058da8f746846922),
    .INIT_54(256'he60ffa2fb294a3b4b4b494f1174ed7edd4ddd56d1b34fdfa3180cf539024fc3b),
    .INIT_55(256'h7ef9585a5a5a3ad7c9f2c8b7b4b4b434be19ea220340d1d57bd7cf14c402a0f3),
    .INIT_56(256'h2d2ddda760554101a294afd3a7667e72088081da2c27cb4f3323600b0958dd16),
    .INIT_57(256'hcfba9b282d2d2d550a7b0bbd4f30aca903103caf3adbba880c704ae73f1f282d),
    .INIT_58(256'h49fb349cbc498329124b8254118489c26400181b3677488894d797969696aea4),
    .INIT_59(256'hd67d25fa04789746e3f0dec82d000a58e5459e35698c4a4b4b4bb72e548dc185),
    .INIT_5A(256'hcb022e4a63c92238a100eae5a9207bea7e81a5a5a5a59bc444c93af73f466502),
    .INIT_5B(256'h05bff8ca0c800aa5dd92178f3fa3d2d2d2520e0ce0c82ed1b4db1aa442acbace),
    .INIT_5C(256'h05408c76c836e1da9f40696969e9f469d22fc90b5e149b577d3745127c8efc9c),
    .INIT_5D(256'h3bd4a0de11abb4b4b49415c48235fb2facf9afde3ed848e040bc4e23702b6bda),
    .INIT_5E(256'h36515a5a5afafaa307bba4b4b4b4745a1f21131bd077ddfd995d3e2303c0b453),
    .INIT_5F(256'h2d9d6413cc1c988cc632859806cfc2a12be54c443d6cb04b0190f2ea814792c3),
    .INIT_60(256'h8cc3870eeb4c0435b80143e65a979089c9bc220c0570203aa7fd99ceda2e2d2d),
    .INIT_61(256'h105e9aa681ed4c15ece53b8ad318a25f0020118f382b9abe7697969696be7496),
    .INIT_62(256'hc7f9d4353460842f9dda224301421b5094d3d1c6a04a4b4b4b77069b48808945),
    .INIT_63(256'h6b5e5f68180fd0baab69b38764a8a398c7a5a5a5a5737b338bee4b4b4b4b013e),
    .INIT_64(256'h0188d8190177ecf2ac794bd4bed2d2d2d26f082557faa5a5a5a53ca47e5c8b6a),
    .INIT_65(256'h6aa09af5da5f50ce4d696969e9297661a7146b7df3ab5cac7b29494e1087fad0),
    .INIT_66(256'h9cf4fe4db9b4b4b414480b5a8e796969696928ea6ac2ae328b32b5c45d96a3ee),
    .INIT_67(256'h595a5a5a3ac37ec491b5b4b4b474abb18c2b17c1dd9fc0f6d1b9ee6c4b222833),
    .INIT_68(256'hc51e33cf040e7f8db3383b2f02391dfa8cc7324c2492acbbba689281973fba12),
    .INIT_69(256'he82f2d2d2dfd503b6d2151c0e215084b87fd3bdb6a48774667c5779a2f2d2d2d),
    .INIT_6A(256'h0aca1926b0592180692f8bfb89969d6dfde71fa8dc52d7029796969612af4ba0),
    .INIT_6B(256'hff53ed0571b01d69358775574986dc84d53fccfa4a4b4b4b11d543329db5fb73),
    .INIT_6C(256'hc44d237de38f170043ae025db05f0f9ba5a5a5a51ba61379354a4b4b4bb5470a),
    .INIT_6D(256'h50dbdd805650ecbb28f05fa3d2d2d2d25b55a63177b917e7f4d533c487e70287),
    .INIT_6E(256'hb838e7b014fa9157696969e92b9d74b20bc8e70eb992d182cd08197e7a171624),
    .INIT_6F(256'h141b53b5b4b4b414c897cca479c6018a1b4aa430e05c01f33f3fd3676cc90580),
    .INIT_70(256'h9716d8f01373ca3cbdb4b4b4549d46c19e13e78568b2d42d714f77d552af5053),
    .INIT_71(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_72(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_73(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_74(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_75(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_76(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_77(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_78(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_79(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_7A(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_7B(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_7C(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_7D(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_7E(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INIT_7F(256'h0000000000000000000000000000000000000000000000000000000000000000),
    
    .INITP_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
    .INITP_0F(256'h0000000000000000000000000000000000000000000000000000000000000000)
  ) BRAM_SINGLE_MACRO_inst (
    .DO(mem_data),   // Output data, width defined by READ_WIDTH parameter
    .ADDR(mem_addr), // Input address, width defined by read/write port depth
    .CLK(clk),       // 1-bit input clock
    .DI(8'h00),      // Input data port, width defined by WRITE_WIDTH parameter
    .EN(1'b1),       // 1-bit input RAM enable
    .REGCE(1'b1),    // 1-bit input output register enable
    .RST(mem_rst),   // 1-bit input reset
    .WE(1'b0)        // Input write enable, width defined by write port depth
  );
 
  // End of BRAM_SINGLE_MACRO_inst instantiation

  // small machine to step through the memory and
  // shift the data out to the DUT
  always @( posedge clk ) begin
    if( !rst_n ) begin
      cstate <= INIT_STATE;
    end
    else begin
      cstate <= nstate;
    end
  end

  always @* begin
    case( cstate )

      // Machine will start in this state following reset
      // and will use the state to allow the address time
      // to affect the memory output
      INIT_STATE : begin
        load   <= 1'b0;
        shift  <= 1'b0;
        led    <= 1'b0;

        if( count_tc ) begin
          nstate <= LATCH_DATA;
        end
        else begin
          nstate <= INIT_STATE;
        end
      end

      // Latch the output data that come out at the clock
      // edge as the 8-bit string to send next
      LATCH_DATA : begin
        load   <= 1'b1;
        shift  <= 1'b0;
        led    <= 1'b0;
        nstate <= SHIFT_DATA;
      end

      // Allow the shift register time to work to deliver
      // the output of the memory bit-by-bit to the DUT
      SHIFT_DATA : begin
        load  <= 1'b0;
        shift <= 1'b1;
        led   <= 1'b0;

        if( count_tc ) begin
          if( max_mem_addr ) begin
            nstate <= DONE_STATE;
          end
          else begin
            nstate <= LATCH_DATA;
          end
        end
        else begin
          nstate <= SHIFT_DATA;
        end
      end

      // Terminal state
      DONE_STATE : begin
        load   <= 1'b0;
        shift  <= 1'b0;
        led    <= 1'b1;
        nstate <= DONE_STATE;
      end

    endcase
  end

  // This address counter initializes to zero on reset
  // and is incremented at each load to be able to get
  // the next value from memory
  always @( posedge clk ) begin
    if( !rst_n ) begin
      mem_addr <= 0;
    end
    else begin
      if( load ) begin

        // Saturating
        if( max_mem_addr ) begin
          mem_addr <= mem_addr;
        end
        else begin
          mem_addr <= mem_addr + 1;
        end
      end
      else begin
        mem_addr <= mem_addr;
      end
    end
  end

  // Shift register state counter supporting the number
  // of times that the shift register is shifted
  always @( posedge clk ) begin
    if( !rst_n ) begin
      count <= 0;
    end
    else begin
      if( load ) begin
        count <= 0;
      end
      else begin
        count <= count + 1;
      end
    end
  end

  assign count_tc = ( count == 6 );

  // Shift register for driving the data to the DUT
  always @( posedge clk ) begin
    if( !rst_n ) begin
      shift_reg <= 0;
    end
    else begin
      if( load ) begin
        shift_reg <= mem_data;
      end
      else begin
        if( shift ) begin
          shift_reg <= {shift_reg, 1'b0};
        end
        else begin
          shift_reg <= shift_reg;
        end
      end
    end
  end

  assign data = shift_reg[7];

  // use the select inputs from a switches to choose
  // between the various counters to send to the
  // seven segment display
  always @* begin
    case( sw )
      SW_TOTAL_SEL       : hex_disp_val <= total_cnt;
      SW_SKYPE_SEL       : hex_disp_val <= skype_cnt;
      SW_SKYPE_SESS_SEL  : hex_disp_val <= skype_session;
      SW_SSH_SEL         : hex_disp_val <= ssh_cnt;
      SW_SSH_SESS_SEL    : hex_disp_val <= ssh_session;
      SW_TELNET_SEL      : hex_disp_val <= telnet_cnt;
      SW_TELNET_SESS_SEL : hex_disp_val <= telnet_session;
      SW_FTP_SEL         : hex_disp_val <= ftp_cnt;
      SW_HTTPS_SEL       : hex_disp_val <= https_cnt;
      SW_SNMP_SEL        : hex_disp_val <= snmp_cnt;
      SW_SMTP_SEL        : hex_disp_val <= smtp_cnt;
      SW_NNTP_SEL        : hex_disp_val <= nntp_cnt;
      default            : hex_disp_val <= {14{1'b1}};
    endcase
  end

  hex2dec_9999 BCD_conv (
    .hex( hex_disp_val ),
    .digit0( digit0 ),
    .digit1( digit1 ),
    .digit2( digit2 ),
    .digit3( digit3 ),
    .digit4( digit4 )
  );

  // instantiate a display controller
  seg7drv_4 #(
    .TIMER_WIDTH( 20 )
  ) seg7driver (
    .clk( clk ),
    .rst_n( rst_n ),
    .digit0( digit0 ),
    .digit1( digit1 ),
    .digit2( digit2 ),
    .digit3( digit3 ),
    .anodes( an ),
    .cathodes( cathodes )
  );

  assign { seg7, dp } = cathodes;

  // instantiate the DUT
  inspector DUT (
    .rst_n( rst_n ),
    .clk( clk ),
    .data( data ),
    .total_cnt( total_cnt ),
    .skype_cnt( skype_cnt ),
    .ftp_cnt( ftp_cnt ),
    .https_cnt( https_cnt ),
    .ssh_cnt( ssh_cnt ),
    .telnet_cnt( telnet_cnt ),
    .snmp_cnt( snmp_cnt ),
    .smtp_cnt( smtp_cnt ),
    .nntp_cnt( nntp_cnt ),
    .skype_session( skype_session ),
    .ssh_session( ssh_session ),
    .telnet_session( telnet_session )
  );

endmodule
