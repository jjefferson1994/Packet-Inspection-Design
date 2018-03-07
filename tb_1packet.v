// TEST 1 packet
// 1 start pattern (A5A5A5A5)
// No "noise"
// 1 Packet: SSH port number (22), session number (7)
// Total count = 1;

module tb_1packet;

	reg rst_n, clk, data;
	wire[31:0] total_cnt;
	wire[7:0] skype_cnt;
	wire[7:0] ftp_cnt;
	wire[7:0] https_cnt;
	wire[7:0] telnet_cnt;
	wire[7:0] ssh_cnt;
	wire[7:0] snmp_cnt;
	wire[7:0] smtp_cnt;
	wire[7:0] nntp_cnt;
	wire[7:0] telnet_session;
	wire[7:0] skype_session;
	wire[7:0] ssh_session;

	integer i, j, k;
	
	inspector DUT (rst_n, data, clk, 
					total_cnt, skype_cnt, ftp_cnt, https_cnt, 
					telnet_cnt, ssh_cnt, snmp_cnt, smtp_cnt,
					nntp_cnt, telnet_session, skype_session, ssh_session);

	always
		#5 clk = !clk;

	initial
	begin
		rst_n = 0;
		clk = 0;
		
		#20
		rst_n = 1;

		#10 data = 0;
		#10 data = 1;
		#10 data = 0;
		#10 data = 1;
		#10 data = 0;
		#10 data = 0;
		#10 data = 1;
		#10 data = 0;
		#10 data = 1; // found A5 sequence 1x

		#10 data = 1;
		#10 data = 0;
		#10 data = 1;
		#10 data = 0;
		#10 data = 0;
		#10 data = 1;
		#10 data = 0;
		#10 data = 1; // found A5 sequence 2x

		#10 data = 1;
		#10 data = 0;
		#10 data = 1;
		#10 data = 0;
		#10 data = 0;
		#10 data = 1;
		#10 data = 0;
		#10 data = 1; // found A5 sequence 3x

		#10 data = 1;
		#10 data = 0;
		#10 data = 1;
		#10 data = 0;
		#10 data = 0;
		#10 data = 1;
		#10 data = 0;
		#10 data = 1; // found A5 sequence 4x

		// bits 1-64
		for(i=1; i<=64; i=i+1)
			#10 data = 0;
		
		// port number size is 2B
		// port number = 22 (SSH)
		#10 data = 0;
		#10 data = 0;
		#10 data = 0;
		#10 data = 0;
		#10 data = 0;
		#10 data = 0;
		#10 data = 0;
		#10 data = 0; // 1B, bit 72

		#10 data = 0;
		#10 data = 0;
		#10 data = 0;
		#10 data = 1;
		#10 data = 0;
		#10 data = 1;
		#10 data = 1;
		#10 data = 0; // 2B, bit 80

		// bits 81-136
		for(j=81; j<=136; j=j+1)
			#10 data = 0;

		// session number size is 1B
		// session number = 7;
		#10 data = 0;
		#10 data = 0;
		#10 data = 0;
		#10 data = 0;
		#10 data = 0;
		#10 data = 1;
		#10 data = 1;
		#10 data = 1; // 1B, bit 144

		// finish 1 packet
		// bits 145-256
		for(k=145; k<=256; k=k+1)
			#10 data = 0;

		#20 $stop;
	end

endmodule
