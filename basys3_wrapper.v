//
// Simple wrapper module to support synthesis of
// an inspector project.  The inputs and outputs
// are present only to ensure that none of the
// logic internal to the block is optimized away.
//
// There is little functionality to the block.  The
// sel input comes from SW3:SW0 on the dev board
// and is used to select the counter that is
// output to the LD7:LD0 according to the table
// below.
//
//    SW3:SW0     LD7:LD0
//     0          8'hFF
//     1          total_cnt[31:24]
//     2          total_cnt[23:16]
//     3          total_cnt[15:8]
//     4          total_cnt[7:0]
//     5          skype_cnt
//     6          skype_session
//     7          ssh_cnt
//     8          ssh_session
//     9          telnet_cnt
//     a          telnet_session
//     b          ftp_cnt
//     c          https_cnt
//     d          snmp_cnt
//     e          smtp_cnt
//     f          nntp_cnt
//
// For this demonstration, no counts will appear
// on the outputs since there is no data being
// sent.  Again, it's just a wrapper.
//
// USE
//
// 1. Create a new project
// 2. Add Files ...
// 3. Add your inspector and this wrapper
// 4. Add Files ...
// 5. Add the provided wrapper XDC file
// 6. Generate Bitstream
// 7. Implementation Utilization Report
//
module basys3_wrapper(
  input clk, rst, data,
  input      [3:0] sel,
  output reg [7:0] counts
);

  // necessary to use button for reset
  wire rst_n;

  // declaration of connections
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

  assign rst_n = ~rst;

  always @* begin
    case( sel )
      4'h1    : counts <= total_cnt[31:24];
      4'h2    : counts <= total_cnt[23:16];
      4'h3    : counts <= total_cnt[15:8];
      4'h4    : counts <= total_cnt[7:0];
      4'h5    : counts <= skype_cnt;
      4'h6    : counts <= skype_session;
      4'h7    : counts <= ssh_cnt;
      4'h8    : counts <= ssh_session;
      4'h9    : counts <= telnet_cnt;
      4'hA    : counts <= telnet_session;
      4'hB    : counts <= ftp_cnt;
      4'hC    : counts <= https_cnt;
      4'hD    : counts <= snmp_cnt;
      4'hE    : counts <= smtp_cnt;
      4'hF    : counts <= nntp_cnt;
      default : counts <= 8'hff;
    endcase
  end

  inspector wrap (
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
