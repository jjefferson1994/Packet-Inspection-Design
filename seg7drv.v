//
// Seven segment display decoder
//
module seg7decode (
  input      [4:0] char,
  output reg [6:0] seg7
);

  always @* begin
    casex( char )
      5'h1x   : seg7 <= 7'b1111110;         // -
      5'h00   : seg7 <= 7'b0000001;         // 0
      5'h01   : seg7 <= 7'b1001111;         // 1
      5'h02   : seg7 <= 7'b0010010;         // 2
      5'h03   : seg7 <= 7'b0000110;         // 3
      5'h04   : seg7 <= 7'b1001100;         // 4
      5'h05   : seg7 <= 7'b0100100;         // 5
      5'h06   : seg7 <= 7'b0100000;         // 6
      5'h07   : seg7 <= 7'b0001111;         // 7
      5'h08   : seg7 <= 7'b0000000;         // 8
      5'h09   : seg7 <= 7'b0001100;         // 9
      5'h0a   : seg7 <= 7'b0001000;         // A
      5'h0b   : seg7 <= 7'b1100000;         // b
      5'h0c   : seg7 <= 7'b0110001;         // C
      5'h0d   : seg7 <= 7'b1000010;         // d
      5'h0e   : seg7 <= 7'b0110000;         // E
      5'h0f   : seg7 <= 7'b0111000;         // F
      default : seg7 <= 7'b1111111;         // all off
    endcase
  end

endmodule

//
// Converts a 14-bit hexadecimal number to
// a BCD set of outputs.  Max value is 2^14
// or 16384 decimal requiring 5 digits
//
module hex2dec_9999 (
  input  [13:0] hex,
  output  [4:0] digit0,
  output  [4:0] digit1,
  output  [4:0] digit2,
  output  [4:0] digit3,
  output  [4:0] digit4
);

  integer i;

  reg [3:0] tths;
  reg [3:0] thou;
  reg [3:0] hund;
  reg [3:0] tens;
  reg [3:0] ones;

  assign digit0 = { hex > 9999 ? 1'b1 : 1'b0, ones };
  assign digit1 = { hex > 9999 ? 1'b1 : 1'b0, tens };
  assign digit2 = { hex > 9999 ? 1'b1 : 1'b0, hund };
  assign digit3 = { hex > 9999 ? 1'b1 : 1'b0, thou };
  assign digit4 = { hex > 9999 ? 1'b1 : 1'b0, tths };

  always @* begin
    tths = 4'd0;
    thou = 4'd0;
    hund = 4'd0;
    tens = 4'd0;
    ones = 4'd0;

    for( i=13; i>=0; i=i-1 ) begin
      // add 3 to columns >= 5
      if( tths >= 5 ) tths = tths + 3;
      if( thou >= 5 ) thou = thou + 3;
      if( hund >= 5 ) hund = hund + 3;
      if( tens >= 5 ) tens = tens + 3;
      if( ones >= 5 ) ones = ones + 3;

      // shift left one
      tths    = tths << 1;
      tths[0] = thou[3];
      thou    = thou << 1;
      thou[0] = hund[3];
      hund    = hund << 1;
      hund[0] = tens[3];
      tens    = tens << 1;
      tens[0] = ones[3];
      ones    = ones << 1;
      ones[0] = hex[i];
    end
  end

endmodule

module seg7drv_4 #(
  parameter TIMER_WIDTH = 22
) (
  input            clk,
  input            rst_n,
  input      [4:0] digit0,
  input      [4:0] digit1,
  input      [4:0] digit2,
  input      [4:0] digit3,
  output reg [3:0] anodes,
  output reg [7:0] cathodes
);

  // counter variables
  wire [TIMER_WIDTH-1:0] cnt_val;
  wire             [1:0] cycle_cnt;

  wire [6:0] ones;
  wire [6:0] tens;
  wire [6:0] hund;
  wire [6:0] thou;

  // anodes are active low
  always @* begin
    case( cycle_cnt )
      0       : anodes <= 4'b1110;
      1       : anodes <= 4'b1101;
      2       : anodes <= 4'b1011;
      3       : anodes <= 4'b0111;
      default : anodes <= 4'b1111;
    endcase
  end

  seg7decode seg7dig0 ( digit0, ones );
  seg7decode seg7dig1 ( digit1, tens );
  seg7decode seg7dig2 ( digit2, hund );
  seg7decode seg7dig3 ( digit3, thou );

  always @* begin
    case( cycle_cnt )
      0       : cathodes <= { ones, 1'b1 };
      1       : cathodes <= { tens, 1'b1 };
      2       : cathodes <= { hund, 1'b1 };
      3       : cathodes <= { thou, 1'b1 };
      default : cathodes <= 8'b11111111;
    endcase
  end

  // counter for cycling display
  counter #( TIMER_WIDTH ) U1 ( clk, rst_n, cnt_val );

  // cycle_cnt is most significant bits
  assign cycle_cnt = cnt_val[ TIMER_WIDTH-1:TIMER_WIDTH-2];

endmodule

module counter #(
  parameter CNT_WIDTH = 8
) (
  input                      clk,
  input                      rst_n,
  output reg [CNT_WIDTH-1:0] count
);

  // counter just free runs rolling over
  // after reaching max value
  always @( posedge clk ) begin
    if( !rst_n ) begin
      count <= 0;
    end
    else begin
      count <= count + 1;
    end
  end

endmodule
