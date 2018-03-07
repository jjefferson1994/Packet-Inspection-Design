module inspector(
input rst_n,
input data,
input clk,
output reg [31:0] total_cnt,
output reg [7:0] skype_cnt,
output reg [7:0] ftp_cnt,
output reg [7:0] https_cnt,
output reg [7:0] telnet_cnt,
output reg [7:0] ssh_cnt,
output reg [7:0] snmp_cnt,
output reg [7:0] smtp_cnt,
output reg [7:0] nntp_cnt,
output reg [7:0] telnet_session,
output reg [7:0] skype_session,
output reg [7:0] ssh_session
);

//these registers are used globally
reg [1:0] startcount;
reg newpacket;

//packet bit counter
reg [255:0] packetcount;

//block for the sequence detector


//reg [3:0] currentseq, nextseq; //registers for the sequence detector
reg busy;

always @ (posedge clk) begin
	if(!rst_n)
		begin
		currentseq <= seq0;
		busy <= 0;
		packetcount <= 0;
		newpacket <= 0;
		port_num <= 0;
		skype_cnt <= 0;
		ftp_cnt <= 0;
		https_cnt <= 0;
		ssh_cnt <= 0;
		telnet_cnt <= 0;
		smtp_cnt <= 0;
		snmp_cnt <= 0;
		nntp_cnt <= 0;
		total_cnt <= 0;
		sessionnum <= 0;
		skypeset <= 0;
		telnetset <= 0;
		sshset <= 0;
		skypeinit <= 0;
		telnetinit <= 0;
		sshinit <= 0;
		end
	else
		begin
		currentseq <= nextseq;
		end
end
always @ (*)//calls to state machines are made above^^^ should happen every clockedge
	begin
		case(currentseq)
		seq0: begin //S0
			startcount <= 0;
			if(data && busy==0)begin
			nextseq <= seq1;
			end
			else begin
			nextseq <= seq0;
			end
		end
		seq1: begin //A1
			if(data)begin
			nextseq <= seq1;
			end
			else begin
			nextseq <= seq2;
			end
		end
		seq2: begin//A10
			if(data)begin
			nextseq <= seq3;
			end
			else begin
			nextseq <= seq0;
			end
		end
		seq3: begin //A101
			if(data)begin
			nextseq <= seq1;
			startcount <= 0;
			end
			else begin
			nextseq <= seq4;
			end
		end
		seq4: begin //A1010
			if(data)begin
			nextseq <= seq3;
			end
			else begin
			nextseq <= seq5;
			end
		end
		seq5: begin //50
			if(data)begin
			nextseq <= seq6;
			end
			else begin
			nextseq <= seq0;
			startcount <= 0;
			end
		end
		seq6: begin //501
			if(data)begin
			nextseq <= seq1;
			startcount <= 0;
			end
			else begin
			nextseq <= seq7;
			end
		end
		seq7: begin //5010
			if(data)begin
			nextseq <= seq8;
			end
			else begin
			nextseq <= seq0
			startcount <=0;
			end
		end
		seq8: begin //50101
			startcount <= startcount + 1; //this should be clocked but check anyways
			if(data)begin
			nextseq <= seq1;
			end
			else begin
			nextseq <= seq0;
			end
			if(startcount == 4) begin//links the start of the new packet to the counter state machine
				newpacket <= 1;
				busy <= 1;
				total_cnt <= total_cnt + 1;
				end
			else
				newpacket <= newpacket;	
		end
		default: begin
		nextseq <= seq0;
		end
		endcase
end

reg [15:0] port_num; 
	
always @ (posedge clk) begin //block for packet counter
	if(newpacket) begin
		packetcount <= packetcount + 1;
		end
	else begin
		packetcount <= packetcount;
	end
end

always @ (posedge clk) begin //checks for port number
	if(packetcount > 63 && packetcount < 81) begin //if im off by one look here first
		port_num = (port_num + data) << 1;
	end
	else begin
		port_num <= port_num;
	end
end

//checks the port number
localparam SKYPE = 16d'23399;
localparam FTP = 16d'20;
localparam HTTPS = 16d'443;
localparam SSH = 16d'22;
localparam TELNET = 16d'23;
localparam SMTP = 16d'25;
localparam SNMP = 16d'161
localparam NNTP = 16d'563;

always @ (posedge clk) begin 
	case(port_num)
	SKYPE:
		skype_cnt <= skype_cnt + 1;
	FTP: 
		ftp_cnt <= ftp_cnt + 1;
	HTTPS:
		https_cnt <= https_cnt + 1;
	SSH:
		ssh_cnt <= ssh_cnt + 1;
	TELNET:
		telnet_cnt <= telnet_cnt + 1;
	SMTP:
		smtp_cnt <= smtp_cnt + 1;
	SNMP:
		snmp_cnt <= snmp_cnt + 1;
	NNTP:
		nntp_cnt <= nntp_cnt + 1;
	default: begin
		skype_cnt <= skype_cnt;
		ftp_cnt <= ftp_cnt;
		https_cnt <= https_cnt;
		ssh_cnt <= ssh_cnt;
		telnet_cnt <= telnet_cnt;
		smtp_cnt <= smtp_cnt;
		snmp_cnt <= snmp_cnt;
		nntp_cnt <= nntp_cnt;
	end
	endcase
end

reg [7:0] sessionnum;
reg [7:0] skypeinit;
reg [7:0] telnetinit;
reg [7:0] sshinit;
//reads in session number
always @ (posedge clk)begin
	if(packetcount > 135 && packetcount < 145) begin
		sessionnum <= (sessionnum + data) << 1;
	end
	else sessionnum <= sessionnum;
end

//checks the session number
reg skypeset;
reg telnetset;
reg sshset;
always @ (posedge clk) begin
	if(port_num == SKYPE && skypeset == 0) begin
		skypeinit <= sessionnum;
		skype_session <= skype_session + 1;
		skypeset <= 1;
	end
	else begin
		skypeinit <= skypeinit;
		skype_session <= skype_session;
		skypeset <= skypeset;
	end
	if(port_num == TELNET && telnetset == 0) begin
		telnetinit <= sessionnum;
		telnet_session <= telnet_session + 1;
		telnetset <= 1;
	end
	else begin
		telnetinit <= telnetinit;
		telnet_session <= telnet_session;
		telnetset <= telnetset;
	end
	if(port_num == SSH && sshset == 0) begin
		sshinit <= sessionnum;
		ssh_session <= ssh_session + 1;
		sshset <= 1;
	end
	else begin
		sshinit <= sshinit;
		ssh_session <= ssh_session;
		sshset <= sshset;
	end
end

endmodule